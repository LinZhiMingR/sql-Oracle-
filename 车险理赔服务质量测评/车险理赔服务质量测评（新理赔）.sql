/*
说明：每次执行只需调整一个日期参数，即统计期末时间
*/

-- ********** 第二项 **********
/*
drop table lzm_end_3501;
drop table lzm_end_comp_3501;
drop table lzm_end_cgg1_3501;
drop table lzm_end_prepay_3501;
drop table lzm_end_jplanfee_3501;
drop table lzm_end_jrefrec_3501;
drop table lzm_end_normal_3501;
drop table lzm_end_r_3501;
*/
-- 01 圈定业务已决案件
create table lzm_end_3501
as
  select /*+ full(l) full(r) parallel(l 8) */
         l.claimno, r.reportdate, r.reporthour, r.Involvewound as rsFlag
  from   prplclaim l
  join   prplregist r
  on     l.registno = r.registno
  where  r.comcode like '3501%'
  and    l.classcode = 'D'
  and    l.casetype not in ('0','1','3')
  and    l.sumpaid <> 0
  and    l.endcasedate >= add_months(date'2016-04-30', -12) + 1
  and    l.endcasedate < date'2016-04-30' + 1
  and    r.Acceptflag = 'Y'
  and    r.Canceldate is null
  and    r.Reportdate >= add_months(date'2016-04-30', -12) + 1
  and    r.Reportdate < date'2016-04-30' + 1;

-- 02 取得对应的计算书
create table lzm_end_comp_3501
as
  select /*+ full(A) full(C) parallel(A 8) */
         B.Claimno, B.Reportdate, B.Reporthour, B.rsFlag, A.Compensateno, A.Sumdutypaid, C.payid --人员收付ID
  from   prplcompensate A
  join   lzm_end_3501 B
  on     A.Claimno = B.Claimno
  join   prplpayinfolist C
  on     A.Compensateno = C.Compensateno
  WHERE  A.Sumdutypaid <> 0
  AND    A.Underwriteflag IN ('1','3');

-- 03 盗抢险案件
create table lzm_end_cgg1_3501
as
  select /*+ full(A) parallel(A 8) */
         distinct B.Claimno
  from   prplloss A
  join   lzm_end_comp_3501 B
  on     A.Compensateno = B.Compensateno
  where  A.kindcode in ('G', 'G1');

-- 04 排除盗抢险案件
delete
from   lzm_end_comp_3501 A
where  exists
       (
        select 'X'
        from   lzm_end_cgg1_3501
        where  claimno = A.Claimno
       );
COMMIT;

-- 05 取得对应的预赔计算书
create table lzm_end_prepay_3501
as
  select A.Claimno, A.Precompensateno, B.Payid
  from   prplprepay A
  join   prplpayinfolist B
  on     A.Precompensateno = B.compensateno
  where  A.Sumprepaid <> 0
  and exists (select 'X'from lzm_end_comp_3501 where lzm_end_comp_3501.claimno = A.Claimno);

-- 06 未支付计算书对应的立案
create table lzm_end_jplanfee_3501
as
  select /*+ parallel(B 8) */
         A.Claimno
  from   lzm_end_comp_3501 A
  join   prpjplanfee B
  on     A.PAYID = B.CERTINO
  group by A.Claimno
  having sum(B.RealPayRefFee) - sum(B.planfee) < 0;

---- 07 计算书支付时间
create table lzm_end_jrefrec_3501
as
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, B.Realpaydate, B.Transtime
  from   lzm_end_comp_3501 A
  join   PrpJrefRec B
  on     A.Payid = B.Certino
  where  B.Certitype = 'C'
  UNION ALL
  select A.Claimno, A.Precompensateno as Compensateno, B.Realpaydate, B.Transtime
  from   lzm_end_prepay_3501 A
  join   PrpJrefRec B
  on     A.Payid = B.Certino
  where  B.Certitype = 'Y';
  
insert into lzm_end_jrefrec_3501
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, B.Realpaydate, B.Transtime
  from   lzm_end_comp_3501 A
  join   PrpJrefRecHis B
  on     A.Payid = B.Certino
  UNION ALL
  select A.Claimno, A.Precompensateno as Compensateno, B.Realpaydate, B.Transtime
  from   lzm_end_prepay_3501 A
  join   PrpJrefRecHis B
  on     A.Payid = B.Certino
  where  B.Certitype = 'Y';
commit;

-- 08 正常结案
create table lzm_end_normal_3501
as
  select A.claimno, A.Reportdate, A.Reporthour, A.rsFlag
  from   (select distinct claimno, Reportdate, Reporthour, rsFlag from lzm_end_comp_3501) A
  where  not exists
         (
          select 'X'
          from   lzm_end_jplanfee_3501
          where  claimno = A.claimno
         )
  and    not exists
         (
          select 'X'
          from   lzm_end_jrefrec_3501
          where  claimno = A.claimno
          and    (Realpaydate > date'2016-04-30' or Realpaydate is null)
         );
-- 09 整合
create table lzm_end_r_3501
as
  select Claimno,
         to_date(to_char(Reportdate, 'yyyy-mm-dd') || ' ' || Reporthour, 'yyyy-mm-dd hh24:mi:ss') as Reportdate,
         to_date(to_char(Realpaydate, 'yyyy-mm-dd') || ' ' || Transtime, 'yyyy-mm-dd hh24:mi:ss') as Realpaydate,
         rsFlag
  from   (
          select A.Claimno, A.Reportdate, A.Reporthour, A.rsFlag, B.Realpaydate, B.Transtime,
                 row_number() over(partition by A.Claimno order by B.Realpaydate desc, B.Transtime desc) as rn
          from   lzm_end_normal_3501 A
          join   lzm_end_jrefrec_3501 B
          on     A.Claimno = B.Claimno
         )
  where  rn = 1;
-- 10 统计
select round(sum(Realpaydate - Reportdate), 4) as 分子,
       count(Claimno) as 分母,
       round(sum(Realpaydate - Reportdate) / count(Claimno), 4) as 案均周期
from   lzm_end_r_3501;
  --  91498.1588  9458  9.6742
  
-- ********** 第一项 **********
-- 基于第二项
/*
drop table lzm_end_r10000_3501;
*/

-- 01 剔除人伤案件
create table lzm_end_r10000_3501
as
  select r.*
  from   lzm_end_r_3501 r
  join   (
          select A.Claimno
          from   lzm_end_comp_3501 A
          where  (rsflag = '0' or rsflag is null)
          group by A.Claimno
          having sum(A.Sumdutypaid) < 10000
         ) b
  on     r.claimno = b.claimno;

-- 03 统计
select round(sum(Realpaydate - Reportdate), 4) as 分子,
       count(Claimno) as 分母,
       round(sum(Realpaydate - Reportdate) / count(Claimno), 4) as 案均周期
from   lzm_end_r10000_3501;
  --  70943.1171  8439  8.4066
  
-- ********** 第三项，第五、六、八项分母 **********
select /*+ full(l) full(r) parallel(l 8) */
       count(case when l.endcasedate >= add_months(date'2016-04-30', -12) + 1
                  and l.endcasedate < date'2016-04-30' + 1
                  then l.claimno else null end) as 第三项分子,
       count(l.claimno) as 第三项分母,
       round(count(case when l.endcasedate >= add_months(date'2016-04-30', -12) + 1
                        and l.endcasedate < date'2016-04-30' + 1
                        then l.claimno else null end) / count(l.claimno), 4) as 第三项车险立案结案率,
       round(count(l.claimno) / 365, 2) as 第五项分母,
       count(case when l.claimdate >= trunc(date'2016-04-30', 'yy')
                  and  l.claimdate < date'2016-04-30' + 1
                  then l.claimno else null end) as 第六项分母,
       count(l.claimno) as 第八项分母
from   prplclaim l
join   prplregist r
on     l.registno = r.registno
where  r.comcode like '3501%'
and    l.classcode = 'D'
and    l.claimdate >= add_months(date'2016-04-30', -12) + 1
and    l.claimdate < date'2016-04-30' + 1;

-- ********** 第八项分子 **********
select /*+ full(B) full(C) parallel(l 8) */
       count(*) as 第八项分子
from   prplrecase A
join   prplclaim B
on     A.claimno = B.claimno
join   prplregist C
on     B.Registno = C.Registno
where  A.opencasedate >= add_months(date'2016-04-30', -12) + 1 
and    A.opencasedate < date'2016-04-30' + 1
and    C.Comcode like '3501%'
and    B.classcode = 'D'
and    B.endcasedate >= add_months(date'2016-04-30', -12) + 1
and    B.endcasedate < date'2016-04-30' + 1;

-- ********** 第四项 **********
/*
drop table lzm_verif_3501;
drop table lzm_verif_r_3501;
*/
-- 01 取得所有核损通过案件
create table lzm_verif_3501
as
  select /*+ full(A) full(B) full(C) full(D) parallel(A 8) */
         d.claimno, C.Reportdate, A.Verifyenddate
  from   Prplcarlossapproval A
  join   prplcomplossapproval B
  on     A.LOSSAPPROVALID = B.LOSSAPPROVALID
  join   prplregist C
  on     B.Registno = C.Registno
  join   prplclaim D
  on     B.Registno = D.Registno
  where  C.Comcode like '3501%'
  and    C.Riskcode like 'D%'
  and    A.Verifyflag in ('1','3')
  and    A.Verifyenddate >= add_months(date'2016-04-30', -12) + 1
  and    A.Verifyenddate < date'2016-04-30' + 1
  and    C.Involvewound = '0';
  
insert into lzm_verif_3501
  select /*+ full(A) full(B) full(C) full(D) parallel(A 8) */
         d.claimno, C.Reportdate, A.Verifyenddate
  from   Prplproplossapproval A
  join   prplcomplossapproval B
  on     A.LOSSAPPROVALID = B.LOSSAPPROVALID
  join   prplregist C
  on     B.Registno = C.Registno
  join   prplclaim D
  on     B.Registno = D.Registno
  where  C.Comcode like '3501%'
  and    C.Riskcode like 'D%'
  and    A.Verifyflag in ('1','3')
  and    A.Verifyenddate >= add_months(date'2016-04-30', -12) + 1
  and    A.Verifyenddate < date'2016-04-30' + 1
  and    C.Involvewound = '0';
commit;

-- 02 取最大核损完成日期
create table lzm_verif_r_3501
as
  select t.claimno, t.reportdate, max(t.verifyenddate) as verifyenddate
  from   lzm_verif_3501 t
  group by t.claimno,t.reportdate;

-- 04 统计
select count(case when trunc(verifyenddate, 'dd') - trunc(reportdate, 'dd') + 1 <= 30 then claimno else null end) as 分子,
       count(claimno) as 分母,
       round(count(case when trunc(verifyenddate, 'dd') - trunc(reportdate, 'dd') + 1 <= 30 then claimno else null end) / count(claimno), 4) as 及时率
from   lzm_verif_r_3501;
  -- 10323  10464  0.9865
  
-- ********** 第七项 **********
-- 上年末积压未决
/*
drop table lzm_jy_Damage_3501_last;
drop table lzm_jy_unclaim_3501_last;
drop table lzm_jy_unend_3501_last;
drop table lzm_jy_end_jplanfee_3501_last;
drop table lzm_jy_end_jrefrec_3501_last;
drop table lzm_jy_end_pay_3501_last;
drop table lzm_jy_end_claim_3501_last;
*/
-- 01 所有福建车险的出险日期
create table lzm_jy_Damage_3501_last
as
  select /*+ full(A) full(B) parallel(A 8) */
         B.Registno
         ,A.Damagestartdate
  from   prplaccidentinfo A
  join   prplaccidentcaserelated B
  on     A.Accidentno = B.Accidentno
  where  B.Comcode like '3501%'
  and    B.classcode = 'D'
  and    A.Damagestartdate < date'2016-04-30' + 1;
  
-- 02 已报未立
create table lzm_jy_unclaim_3501_last
as
  select /*+ full(A) parallel(A 8) */
         A.Registno
  from   PrpLregist A
  left outer join
         (
          select /*+ full(l) parallel(l 8) */
                 distinct registno
          from   PrpLclaim l
          where  claimdate < trunc(date'2016-04-30', 'yy')
          and    Classcode = 'D'
         ) B
  on     A.Registno = B.Registno
  join   lzm_jy_Damage_3501_last C
  on     A.Registno = C.Registno
  where  A.AcceptFlag = 'Y'
  and    (A.CancelDate is null or A.canceldate > trunc(date'2016-04-30', 'yy'))
  and    C.damagestartdate < trunc(date'2016-04-30', 'yy')
  and    A.reportdate < trunc(date'2016-04-30', 'yy')
  and    A.Comcode like '3501%'
  and    A.Classcode = 'D'
  and    B.Registno is null;

         
-- 03 已立未决
create table lzm_jy_unend_3501_last
as
  select /*+ full(B) parallel(B 8) */
         A.Registno,
         B.Claimno,
         C.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Canceldate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype,
         B.recancelflag
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  join   lzm_jy_Damage_3501_last C
  on     A.Registno = C.Registno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    C.Damagestartdate < trunc(date'2016-04-30', 'yy')
  and    A.Reportdate < trunc(date'2016-04-30', 'yy')
  and    A.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Claimdate < trunc(date'2016-04-30', 'yy')
  and    (B.Endcasedate > trunc(date'2016-04-30', 'yy') or B.Endcasedate is null);
  
-- 04 已决未付
---- 未支付计算书对应的立案
create table lzm_jy_end_jplanfee_3501_last
as
  select /*+ full(A) full(B) full(C) parallel(A 8) */
         A.Claimno
  from   prplcompensate A
  join   prplpayinfolist B
  on     A.Compensateno = B.Compensateno
  join   prpjplanfee C
  on     B.Payid = C.Certino
  where  C.Classcode = 'D'
  and    C.Comcode like '3501%'
  group by A.Claimno
  having sum(C.RealPayRefFee) - sum(C.planfee) < 0;

---- 统计时点之后支付的计算书对应的立案
create table lzm_jy_end_jrefrec_3501_last
as
  select /*+ full(A) full(B) full(C) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   prplpayinfolist B
  on     A.Compensateno = B.Compensateno
  join   PrpJrefRec C
  on     B.Payid = C.Certino
  where  A.Classcode = 'D'
  and    C.Comcode like '3501%'
  and    C.Realpaydate > trunc(date'2016-04-30', 'yy') - 1
  and    C.Riskcode like 'D%';

insert into lzm_jy_end_jrefrec_3501_last
  select /*+ full(A) full(B) full(C) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   prplpayinfolist B
  on     A.Compensateno = B.Compensateno
  join   PrpJrefRecHis C
  on     B.Payid = C.Certino
  where  A.Classcode = 'D'
  and    C.Comcode like '3501%'
  and    C.Realpaydate > trunc(date'2016-04-30', 'yy') - 1
  and    C.Riskcode like 'D%';
commit;

---- 整合立案
create table lzm_jy_end_pay_3501_last
as
  select claimno
  from   lzm_jy_end_jplanfee_3501_last
  UNION
  select claimno
  from   lzm_jy_end_jrefrec_3501_last;

---- 圈定已决未支付的立案
create table lzm_jy_end_claim_3501_last
as
  select /*+ full(A) full(B) parallel(A 8) */
         A.Registno,
         B.Claimno,
         D.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Endcasedate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  join   lzm_jy_end_pay_3501_last C
  on     B.claimno = C.claimno
  join   lzm_jy_Damage_3501_last D
  on     A.Registno = D.Registno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    D.Damagestartdate < trunc(date'2016-04-30', 'yy')
  and    A.Reportdate < trunc(date'2016-04-30', 'yy')
  and    A.Comcode like '3501%'
  and    B.Claimdate < trunc(date'2016-04-30', 'yy')
  and    B.Endcasedate < trunc(date'2016-04-30', 'yy');

-- 统计时点末积压未决
/*
drop table lzm_jy_unclaim_3501_this;
drop table lzm_jy_unend_3501_this;
drop table lzm_jy_end_jplanfee_3501_this;
drop table lzm_jy_end_jrefrec_3501_this;
drop table lzm_jy_end_pay_3501_this;
drop table lzm_jy_end_claim_3501_this;
*/
-- ********** 第七项 **********
-- 01 已报未立
create table lzm_jy_unclaim_3501_this
as
  select /*+ full(A) parallel(A 8) */
         A.Registno
  from   PrpLregist A
  left outer join
         (
          select /*+ full(l) parallel(l 8) */
                 distinct registno
          from   PrpLclaim l
          where  claimdate <= date'2016-04-30'
          and    Classcode = 'D'
         ) B
  on     A.Registno = B.Registno
  join   lzm_jy_Damage_3501_last C
  on     A.Registno = C.Registno
  where  A.AcceptFlag = 'Y'
  and    (A.CancelDate is null or A.canceldate > date'2016-04-30')
  and    C.damagestartdate < date'2016-04-30' + 1
  and    A.reportdate < date'2016-04-30' +1
  and    A.Comcode like '3501%'
  and    A.Classcode = 'D'
  and    B.Registno is null;
        
-- 02 已立未决
create table lzm_jy_unend_3501_this
as
  select /*+ full(B) parallel(B 8) */
         A.Registno,
         B.Claimno,
         C.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Canceldate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype,
         B.recancelflag
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  join   lzm_jy_Damage_3501_last C
  on     A.Registno = C.Registno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    C.Damagestartdate < date'2016-04-30' + 1
  and    A.Reportdate < date'2016-04-30' + 1
  and    A.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Claimdate < date'2016-04-30' + 1
  and    (B.Endcasedate > date'2016-04-30' + 1 or B.Endcasedate is null);

-- 03 已决未付
---- 统计时点之后支付的计算书对应的立案
create table lzm_jy_end_jrefrec_3501_this
as
  select /*+ full(A) full(B) full(C) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   prplpayinfolist B
  on     A.Compensateno = B.Compensateno
  join   PrpJrefRec C
  on     B.Payid = C.Certino
  where  A.Classcode = 'D'
  and    C.Comcode like '3501%'
  and    C.Realpaydate > date'2016-04-30'
  and    C.Riskcode like 'D%';

insert into lzm_jy_end_jrefrec_3501_this
  select /*+ full(A) full(B) full(C) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   prplpayinfolist B
  on     A.Compensateno = B.Compensateno
  join   PrpJrefRecHis C
  on     B.Payid = C.Certino
  where  A.Classcode = 'D'
  and    C.Comcode like '3501%'
  and    C.Realpaydate > date'2016-04-30'
  and    C.Riskcode like 'D%';
commit;

---- 整合立案
create table lzm_jy_end_pay_3501_this
as
  select claimno
  from   lzm_jy_end_jplanfee_3501_last
  UNION
  select claimno
  from   lzm_jy_end_jrefrec_3501_this;

---- 圈定已决未支付的立案
create table lzm_jy_end_claim_3501_this
as
  select /*+ full(A) full(B) parallel(A 8) */
         A.Registno,
         B.Claimno,
         D.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Endcasedate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  join   lzm_jy_end_pay_3501_this C
  on     B.claimno = C.claimno
  join   lzm_jy_Damage_3501_last D
  on     A.Registno = D.Registno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    D.Damagestartdate < date'2016-04-30' + 1
  and    A.Reportdate < date'2016-04-30' + 1
  and    A.Comcode like '3501%'
  and    B.Claimdate < date'2016-04-30' + 1
  and    B.Endcasedate < date'2016-04-30' + 1;

-- 统计
select sum(cnt) as 分母
from   (
select count(*) as cnt from lzm_jy_unclaim_3501_last
UNION ALL
select count(*) as cnt from lzm_jy_unend_3501_last
UNION ALL
select count(*) as cnt from lzm_jy_end_claim_3501_last
       );

-- 已清理
select *
from   (
select registno as bn from lzm_jy_unclaim_3501_last
union all
select claimno as bn from lzm_jy_unend_3501_last
union all
select claimno as bn from lzm_jy_end_claim_3501_last
       )
minus
select *
from   (
select registno as bn from lzm_jy_unclaim_3501_this
union all
select claimno as bn from lzm_jy_unend_3501_this
union all
select claimno as bn from lzm_jy_end_claim_3501_this
       );
                                                                                                                                                                                                                                                                                                                                                    