/*
说明：每次执行只需调整一个日期参数，即统计期末时间
*/

-- ********** 第二项 **********
/*
drop table alan_end_3501;
drop table alan_end_comp_3501;
drop table alan_end_cgg1_3501;
drop table alan_end_prepay_3501;
drop table alan_end_jplanfee_3501;
drop table alan_end_jrefrec_3501;
drop table alan_end_normal_3501;
drop table alan_end_r_3501;
*/
-- 01 圈定业务已决案件
create table alan_end_3501
as
  select /*+ full(l) full(r) parallel(l 8) */
         l.claimno, r.reportdate, r.reporthour, substr(l.escapeflag, 3, 1) as rsFlag
  from   prplclaim l
  join   prplregist r
  on     l.registno = r.registno
  where  l.comcode like '3501%'
  and    l.classcode = 'D'
  and    l.casetype not in ('0', '1')
  and    l.sumpaid <> 0
  and    l.endcasedate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30'
  and    r.Acceptflag = 'Y'
  and    r.Canceldate is null
  and    r.Reportdate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30';

-- 02 取得对应的计算书
create table alan_end_comp_3501
as
  select /*+ full(A) parallel(A 8) */
         B.Claimno, B.Reportdate, B.Reporthour, B.rsFlag, A.Compensateno, A.Sumdutypaid
  from   prplcompensate A
  join   alan_end_3501 B
  on     A.Claimno = B.Claimno
  and    A.Sumdutypaid <> 0;

-- 03 盗抢险案件
create table alan_end_cgg1_3501
as
  select /*+ full(A) parallel(A 8) */
         distinct B.Claimno
  from   prplloss A
  join   alan_end_comp_3501 B
  on     A.Compensateno = B.Compensateno
  where  A.kindcode in ('G', 'G1');
  
-- 04 排除盗抢险案件
delete
from   alan_end_comp_3501 A
where  exists
       (
        select 'X'
        from   alan_end_cgg1_3501
        where  claimno = A.Claimno
       );
commit;

-- 05 取得对应的预赔计算书
create table alan_end_prepay_3501
as
  select A.Claimno, A.Precompensateno
  from   prplprepay A
  join   (select distinct claimno from alan_end_comp_3501) B
  on     A.Claimno = B.Claimno
  where  A.Sumprepaid <> 0;
  
-- 06 未支付计算书对应的立案
create table alan_end_jplanfee_3501
as
  select /*+ parallel(B 8) */
         A.Claimno
  from   alan_end_comp_3501 A
  join   prpjplanfee B
  on     A.Compensateno = B.Certino
  group by A.Claimno
  having sum(B.RealPayRefFee) - sum(B.planfee) < 0;

---- 07 计算书支付时间
create table alan_end_jrefrec_3501
as
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, B.Realpaydate, B.Transtime
  from   alan_end_comp_3501 A
  join   PrpJrefRec B
  on     A.Compensateno = B.Certino
  where  B.Certitype = 'C'
  UNION ALL
  select A.Claimno, A.Precompensateno as Compensateno, B.Realpaydate, B.Transtime
  from   alan_end_prepay_3501 A
  join   PrpJrefRec B
  on     A.Precompensateno = B.Certino
  where  B.Certitype = 'Y';
  
insert into alan_end_jrefrec_3501
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, B.Realpaydate, B.Transtime
  from   alan_end_comp_3501 A
  join   PrpJrefRecHis B
  on     A.Compensateno = B.Certino
  UNION ALL
  select A.Claimno, A.Precompensateno as Compensateno, B.Realpaydate, B.Transtime
  from   alan_end_prepay_3501 A
  join   PrpJrefRecHis B
  on     A.Precompensateno = B.Certino
  where  B.Certitype = 'Y';
commit;

-- 08 正常结案
create table alan_end_normal_3501
as
  select A.claimno, A.Reportdate, A.Reporthour, A.rsFlag
  from   (select distinct claimno, Reportdate, Reporthour, rsFlag from alan_end_comp_3501) A
  where  not exists
         (
          select 'X'
          from   alan_end_jplanfee_3501
          where  claimno = A.claimno
         )
  and    not exists
         (
          select 'X'
          from   alan_end_jrefrec_3501
          where  claimno = A.claimno
          and    (Realpaydate > date'2016-04-30' or Realpaydate is null)
         );
-- 09 整合
create table alan_end_r_3501
as
  select Claimno,
         to_date(to_char(Reportdate, 'yyyy-mm-dd') || ' ' || Reporthour, 'yyyy-mm-dd hh24:mi:ss') as Reportdate,
         to_date(to_char(Realpaydate, 'yyyy-mm-dd') || ' ' || Transtime, 'yyyy-mm-dd hh24:mi:ss') as Realpaydate,
         rsFlag
  from   (
          select A.Claimno, A.Reportdate, A.Reporthour, A.rsFlag, B.Realpaydate, B.Transtime,
                 row_number() over(partition by A.Claimno order by B.Realpaydate desc, B.Transtime desc) as rn
          from   alan_end_normal_3501 A
          join   alan_end_jrefrec_3501 B
          on     A.Claimno = B.Claimno
         )
  where  rn = 1;

-- 10 统计
select round(sum(Realpaydate - Reportdate), 4) as 分子,
       count(Claimno) as 分母,
       round(sum(Realpaydate - Reportdate) / count(Claimno), 4) as 案均周期
from   alan_end_r_3501;
  -- 446939.9298  33551  13.3212
  
-- ********** 第一项 **********
-- 基于第二项
/*
drop table alan_end_r10000_3501;
*/
-- 01 剔除人伤案件
create table alan_end_r10000_3501
as
  select r.*
  from   alan_end_r_3501 r
  join   (
          select A.Claimno
          from   alan_end_comp_3501 A
          where  (rsflag = '0' or rsflag is null)
          group by A.Claimno
          having sum(A.Sumdutypaid) < 10000
         ) b
  on     r.claimno = b.claimno;

-- 03 统计
select round(sum(Realpaydate - Reportdate), 4) as 分子,
       count(Claimno) as 分母,
       round(sum(Realpaydate - Reportdate) / count(Claimno), 4) as 案均周期
from   alan_end_r10000_3501;
  -- 268774.1927  29313  9.1691

-- ********** 第三项，第五、六、八项分母 **********
select /*+ full(l) parallel(l 8) */
       count(case when l.endcasedate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30' then l.claimno else null end) as 第三项分子,
       count(l.claimno) as 第三项分母,
       round(count(case when l.endcasedate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30' then l.claimno else null end) / count(l.claimno), 4) as 第三项车险立案结案率,
       round(count(l.claimno) / 365, 2) as 第五项分母,
       count(case when l.claimdate between trunc(date'2016-04-30', 'yy') and date'2016-04-30' then l.claimno else null end) as 第六项分母,
       count(l.claimno) as 第八项分母
from   prplclaim l
where  l.comcode like '3501%'
and    l.classcode = 'D'
and    l.claimdate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30';

-- ********** 第八项分子 **********
select /*+ full(l) parallel(l 8) */
       count(*) as 第八项分子
from   prplrecase r
join   prplclaim l
on     r.claimno = l.claimno
where  r.opencasedate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30'
and    l.comcode like '3501%'
and    l.classcode = 'D'
and    l.endcasedate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30';

-- ********** 第四项 **********
/*
drop table alan_verif_3501;
drop table alan_verif_r_3501;
*/
-- 01 取得所有核损通过案件
create table alan_verif_3501
as
  select /*+ full(v) parallel(v 8) */
         v.claimno, max(v.underwriteenddate) as underwriteenddate
  from   prplverifyloss v
  where  v.comcode like '3501%'
  and    v.riskcode like 'D%'
  and    v.underwriteflag = '1'
  and    v.underwriteenddate between add_months(date'2016-04-30', -12) + 1 and date'2016-04-30'
  and    v.claimno is not null
  group by v.claimno;

-- 02 剔除人伤案件
create table alan_verif_r_3501
as
  select /*+ full(B) parallel(B 8) */
         A.Claimno,
         C.Reportdate,
         A.Underwriteenddate
  from   alan_verif_3501 A
  join   prplclaim B
  on     A.Claimno = B.Claimno
  join   prplregist C
  on     B.Registno = C.Registno
  where  (substr(B.escapeflag, 3, 1) = '0' or substr(B.escapeflag, 3, 1) is null);
  

-- 04 统计
select count(case when trunc(Underwriteenddate, 'dd') - trunc(Reportdate, 'dd') + 1 <= 30 then claimno else null end) as 分子,
       count(claimno) as 分母,
       round(count(case when trunc(Underwriteenddate, 'dd') - trunc(Reportdate, 'dd') + 1 <= 30 then claimno else null end) / count(claimno), 4) as 及时率
from   alan_verif_r_3501;
  -- 32453  35446  91.56
  
-- ********** 第七项 **********
-- 上年末积压未决
/*
drop table alan_jy_unclaim_3501_last;
drop table alan_jy_unend_3501_last;
drop table alan_jy_end_jplanfee_3501_last;
drop table alan_jy_end_jrefrec_3501_last;
drop table alan_jy_end_pay_3501_last;
drop table alan_jy_end_claim_3501_last;
*/
-- 01 已报未立
create table alan_jy_unclaim_3501_last
as
  select /*+ full(A) parallel(A 8) */
         A.Registno
  from   PrpLregist A
  left outer join
         (
          select /*+ full(l) parallel(l 8) */
                 distinct registno
          from   PrpLclaim l
          where  claimdate <= trunc(date'2016-04-30', 'yy') - 1
          and    Comcode like '3501%'
          and    Classcode = 'D'
         ) B
  on     A.Registno = B.Registno
  where  A.AcceptFlag = 'Y'
  and    (A.CancelDate is null or A.canceldate >= trunc(date'2016-04-30', 'yy') - 1)
  and    A.damagestartdate <= trunc(date'2016-04-30', 'yy') - 1
  and    A.reportdate <= trunc(date'2016-04-30', 'yy') - 1
  and    A.Comcode like '3501%'
  and    A.Classcode = 'D'
  and    B.Registno is null;
  

         
-- 02 已立未决
create table alan_jy_unend_3501_last
as
  select /*+ full(B) parallel(B 8) */
         A.Registno,
         B.Claimno,
         A.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Canceldate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype,
         B.recancelflag
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    A.Damagestartdate <= trunc(date'2016-04-30', 'yy') - 1
  and    A.Reportdate <= trunc(date'2016-04-30', 'yy') - 1
  and    A.Classcode = 'D'
  and    B.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Claimdate <= trunc(date'2016-04-30', 'yy') - 1
  and    (B.Endcasedate > trunc(date'2016-04-30', 'yy') - 1 or B.Endcasedate is null);
  
  
-- 03 已决未付
---- 未支付计算书对应的立案
create table alan_jy_end_jplanfee_3501_last
as
  select /*+ full(A) parallel(A 8) */
         A.Claimno
  from   prplcompensate A
  join   prpjplanfee B
  on     A.Compensateno = B.Certino
  where  A.Classcode = 'D'
  and    A.Comcode like '3501%'
  group by A.Claimno
  having sum(B.RealPayRefFee) - sum(B.planfee) < 0;
  

---- 统计时点之后支付的计算书对应的立案
create table alan_jy_end_jrefrec_3501_last
as
  select /*+ full(A) full(B) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   PrpJrefRec B
  on     A.Compensateno = B.Certino
  where  A.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Realpaydate > trunc(date'2016-04-30', 'yy') - 1
  and    B.Riskcode like 'D%';


insert into alan_jy_end_jrefrec_3501_last
  select /*+ full(A) full(B) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   PrpJrefRecHis B
  on     A.Compensateno = B.Certino
  where  A.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Realpaydate > trunc(date'2016-04-30', 'yy') - 1
  and    B.Riskcode like 'D%';
commit;

---- 整合立案
create table alan_jy_end_pay_3501_last
as
  select claimno
  from   alan_jy_end_jplanfee_3501_last
  UNION
  select claimno
  from   alan_jy_end_jrefrec_3501_last;
  

---- 圈定已决未支付的立案
create table alan_jy_end_claim_3501_last
as
  select /*+ index(B PK_LCLAIM) index(A PK_LREGIST) */
         A.Registno,
         B.Claimno,
         A.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Endcasedate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  join   alan_jy_end_pay_3501_last C
  on     B.claimno = C.claimno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    A.Damagestartdate <= trunc(date'2016-04-30', 'yy') - 1
  and    A.Reportdate <= trunc(date'2016-04-30', 'yy') - 1
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Claimdate <= trunc(date'2016-04-30', 'yy') - 1
  and    B.Endcasedate <= trunc(date'2016-04-30', 'yy') - 1;
  

-- 统计时点末积压未决
/*
drop table alan_jy_unclaim_3501_this;
drop table alan_jy_unend_3501_this;
drop table alan_jy_end_jplanfee_3501_this;
drop table alan_jy_end_jrefrec_3501_this;
drop table alan_jy_end_pay_3501_this;
drop table alan_jy_end_claim_3501_this;
*/
-- ********** 第七项 **********
-- 01 已报未立
create table alan_jy_unclaim_3501_this
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
          and    Comcode like '3501%'
          and    Classcode = 'D'
         ) B
  on     A.Registno = B.Registno
  where  A.AcceptFlag = 'Y'
  and    (A.CancelDate is null or A.canceldate >= date'2016-04-30')
  and    A.damagestartdate <= date'2016-04-30'
  and    A.reportdate <= date'2016-04-30'
  and    A.Comcode like '3501%'
  and    A.Classcode = 'D'
  and    B.Registno is null;
  
-- 02 已立未决
create table alan_jy_unend_3501_this
as
  select /*+ full(B) parallel(B 8) */
         A.Registno,
         B.Claimno,
         A.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Canceldate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype,
         B.recancelflag
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    A.Damagestartdate <= date'2016-04-30'
  and    A.Reportdate <= date'2016-04-30'
  and    A.Classcode = 'D'
  and    B.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Claimdate <= date'2016-04-30'
  and    (B.Endcasedate > date'2016-04-30' or B.Endcasedate is null);
  
-- 03 已决未付
---- 未支付计算书对应的立案
create table alan_jy_end_jplanfee_3501_this
as
  select /*+ full(A) parallel(A 8) */
         A.Claimno
  from   prplcompensate A
  join   prpjplanfee B
  on     A.Compensateno = B.Certino
  where  A.Classcode = 'D'
  and    A.Comcode like '3501%'
  group by A.Claimno
  having sum(B.RealPayRefFee) - sum(B.planfee) < 0;
  
---- 统计时点之后支付的计算书对应的立案
create table alan_jy_end_jrefrec_3501_this
as
  select /*+ full(A) full(B) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   PrpJrefRec B
  on     A.Compensateno = B.Certino
  where  A.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Realpaydate > date'2016-04-30'
  and    B.Riskcode like 'D%';

insert into alan_jy_end_jrefrec_3501_this
  select /*+ full(A) full(B) parallel(A 8) */
         distinct A.Claimno
  from   prplcompensate A
  join   PrpJrefRecHis B
  on     A.Compensateno = B.Certino
  where  A.Classcode = 'D'
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Realpaydate > date'2016-04-30'
  and    B.Riskcode like 'D%';
commit;


---- 整合立案
create table alan_jy_end_pay_3501_this
as
  select claimno
  from   alan_jy_end_jplanfee_3501_this
  UNION
  select claimno
  from   alan_jy_end_jrefrec_3501_this;
  

---- 圈定已决未支付的立案
create table alan_jy_end_claim_3501_this
as
  select /*+ index(B PK_LCLAIM) index(A PK_LREGIST) */
         A.Registno,
         B.Claimno,
         A.Damagestartdate,
         A.Reportdate,
         B.Claimdate,
         B.Endcasedate,
         decode(B.casetype, 0, '注销', 1, '拒赔', 2, '结案', null) as casetype
  from   prplregist A
  join   prplclaim B
  on     A.Registno = B.Registno
  join   alan_jy_end_pay_3501_this C
  on     B.claimno = C.claimno
  where  A.Acceptflag = 'Y'
  and    A.Canceldate is null
  and    A.Damagestartdate <= date'2016-04-30'
  and    A.Reportdate <= date'2016-04-30'
  and    A.Comcode like '3501%'
  and    B.Comcode like '3501%'
  and    B.Claimdate <= date'2016-04-30'
  and    B.Endcasedate <= date'2016-04-30';

-- 统计
select sum(cnt) as 分母
from   (
select count(*) as cnt from alan_jy_unclaim_3501_last
UNION ALL
select count(*) as cnt from alan_jy_unend_3501_last
UNION ALL
select count(*) as cnt from alan_jy_end_claim_3501_last
       );

-- 已清理
select *
from   (
select registno as bn from alan_jy_unclaim_3501_last
union all
select claimno as bn from alan_jy_unend_3501_last
union all
select claimno as bn from alan_jy_end_claim_3501_last
       )
minus
select *
from   (
select registno as bn from alan_jy_unclaim_3501_this
union all
select claimno as bn from alan_jy_unend_3501_this
union all
select claimno as bn from alan_jy_end_claim_3501_this
       );
                                                                                                                                                                                                                                                                                                                