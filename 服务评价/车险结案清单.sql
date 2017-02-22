--------------------------------------------------------------------------------------------
--****************         老理赔           *****************--
--------------------------------------------------------------------------------------------
drop table lzm_end_pay_claimno_1;
drop table lzm_end_pay_claimno_2;
drop table lzm_end_pay_claimno_3;
drop table lzm_end_pay_paid;
drop table lzm_end_claim_normal;
drop table lzm_end_claim_special;
drop table lzm_end_claim_all;
drop table lzm_end_claim;
drop table lzm_end_claim_sumdutypaid;
drop table lzm_end_claim_toubaoren;
drop table lzm_end_claim_cgg1;
drop table lzm_end_claim_recase;
drop table lzm_end_claim_handler;
drop table lzm_end_claim_list;

--老理赔结案
-- 1 未支付计算书对应的立案
create table lzm_end_pay_claimno_1
as
  select /*+ parallel(A 8) */
         A.Claimno, nvl(trim(substr(A.Flag, 4, 1)), '0') as flag
  from   prplcompensate A
  join   prpjplanfee B
  on     A.Compensateno = B.Certino
  where  a.underwriteflag in ('1','3')
  group by A.Claimno, nvl(trim(substr(A.Flag, 4, 1)), '0')
  having sum(B.RealPayRefFee) - sum(B.planfee1) < 0;

-- 2 统计期初之后的支付信息
create table lzm_end_pay_claimno_2
as
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, nvl(trim(substr(A.Flag, 4, 1)), '0') as flag, A.Underwriteenddate, A.Underwritename, A.Lawsuitflag, B.Realpaydate, B.Transtime
  from   prplcompensate A
  join   PrpJrefRec B
  on     A.Compensateno = B.Certino
  where  B.Realpaydate > trunc(date'2016-04-30','yy')-1
  and    a.recancelflag is null
  and    a.underwriteflag in ('1','3')
  UNION ALL
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, nvl(trim(substr(A.Flag, 4, 1)), '0') as flag, A.Underwriteenddate, A.Underwritename, A.Lawsuitflag, B.Realpaydate, B.Transtime
  from   prplcompensate A
  join   PrpJrefRecHis B
  on     A.Compensateno = B.Certino
  where  B.Realpaydate > trunc(date'2016-04-30','yy')-1
  and    a.recancelflag is null
  and    a.underwriteflag in ('1','3');

-- 3 统计期之前的支付，统计期内结案的信息
create table lzm_end_pay_claimno_3
as
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, nvl(trim(substr(A.Flag, 4, 1)), '0') as flag,B.Realpaydate, B.Transtime
  from   prplcompensate A
  join   PrpJrefRec B
  on     A.Compensateno = B.Certino
  join   prplclaim c
  on     a.claimno = c.claimno
  and    c.endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30'
  where  a.recancelflag is null
  and    c.recancelflag is null
  and    b.realpaydate is not null
  and    a.underwriteflag in ('1','3')
  and not exists (select 1 from lzm_end_pay_claimno_1 d where d.claimno = a.claimno)
  and not exists (select 1 from lzm_end_pay_claimno_2 e where e.claimno = a.claimno)
  UNION ALL
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, nvl(trim(substr(A.Flag, 4, 1)), '0') as flag,B.Realpaydate, B.Transtime
  from   prplcompensate A
  join   PrpJrefRechis B
  on     A.Compensateno = B.Certino
  join   prplclaim c
  on     a.claimno = c.claimno
  and    c.endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30'
  where  a.recancelflag is null
  and    c.recancelflag is null
  and    b.realpaydate is not null
  and    a.underwriteflag in ('1','3')
  and not exists (select 1 from lzm_end_pay_claimno_1 d where d.claimno = a.claimno)
  and not exists (select 1 from lzm_end_pay_claimno_2 e where e.claimno = a.claimno)
  --重开案重开前支付日期
  union all
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, nvl(trim(substr(A.Flag, 4, 1)), '0') as flag,B.Realpaydate, B.Transtime
  from   prplcompensate A
  join   PrpJrefRec B
  on     A.Compensateno = B.Certino
  join   prplrecase c
  on     a.claimno = c.claimno
  and    c.endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30'
  where  a.recancelflag is null
  and    c.recancelflag ='01'
  and    b.realpaydate is not null
  and    a.underwriteflag in ('1','3')
  and not exists (select 1 from prplvirtualclaim f where f.claimno = a.claimno and f.validstatus in ('8','7')
              and c.OPENCASEDATE>=f.canceldate)  
  and not exists (select 1 from lzm_end_pay_claimno_1 d where d.claimno = a.claimno)
  and not exists (select 1 from lzm_end_pay_claimno_2 e where e.claimno = a.claimno)
  UNION ALL
  select /*+ full(B) parallel(B 8) */
         A.Claimno, A.Compensateno, nvl(trim(substr(A.Flag, 4, 1)), '0') as flag,B.Realpaydate, B.Transtime
  from   prplcompensate A
  join   PrpJrefRechis B
  on     A.Compensateno = B.Certino
  join   prplrecase c
  on     a.claimno = c.claimno
  and    c.endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30'
  where  a.recancelflag is null
  and    c.recancelflag ='01'
  and    b.realpaydate is not null
  and    a.underwriteflag in ('1','3')
  and not exists (select 1 from prplvirtualclaim f where f.claimno = a.claimno and f.validstatus in ('8','7')
         and c.OPENCASEDATE>=f.canceldate)
  and not exists (select 1 from lzm_end_pay_claimno_1 d where d.claimno = a.claimno)
  and not exists (select 1 from lzm_end_pay_claimno_2 e where e.claimno = a.claimno);
  
-- 4 统计期内支付完成的案件
create table lzm_end_pay_paid
as
  select *
  from   (
          select Claimno, flag, Realpaydate, Transtime, realpayTime
          from   (
                  select /*+ parallel(A 8) */
                         A.Claimno, A.flag, A.Realpaydate, A.Transtime,
                         to_date(to_char(A.Realpaydate, 'yyyy-mm-dd') || ' ' || A.Transtime, 'yyyy-mm-dd hh24:mi:ss') as realpayTime,
                         row_number() over(partition by A.Claimno, A.flag order by to_date(to_char(A.Realpaydate, 'yyyy-mm-dd') || ' ' || A.Transtime, 'yyyy-mm-dd hh24:mi:ss') desc) as rn
                  from   lzm_end_pay_claimno_2 A
                  left outer join
                         lzm_end_pay_claimno_1 B
                  on     A.Claimno = B.Claimno and A.Flag = B.Flag
                  where  B.Claimno is null
                 )
          where  rn = 1
         )
  where  Realpaydate between trunc(date'2016-04-30','yy') and date'2016-04-30';
  
insert into lzm_end_pay_paid
  select Claimno, flag, Realpaydate, Transtime, realpayTime
  from   (
          select /*+ parallel(A 8) */
                 A.Claimno, A.flag, A.Realpaydate, A.Transtime,
                 to_date(to_char(A.Realpaydate, 'yyyy-mm-dd') || ' ' || A.Transtime, 'yyyy-mm-dd hh24:mi:ss') as realpayTime,
                 row_number() over(partition by A.Claimno, A.flag order by to_date(to_char(A.Realpaydate, 'yyyy-mm-dd') || ' ' || A.Transtime, 'yyyy-mm-dd hh24:mi:ss') desc) as rn
          from   lzm_end_pay_claimno_3 A
         )
  where  rn = 1;
commit;

-- 5 圈定统计期已决立案
create table lzm_end_claim_normal
as
  select a.claimno
         ,b.flag
         ,'正常结案' as casetype
         ,a.endcasedate
         ,b.realpaytime
  from   prplclaim a
  join   lzm_end_pay_paid b
  on     a.Claimno = b.Claimno
  where  greatest(a.endcasedate,b.realpaydate) between trunc(date'2016-04-30','yy') and date'2016-04-30'
  and    a.recancelflag is null
  and    a.classcode = 'D'
  union all
  select a.claimno
         ,b.flag
         ,'正常结案' as casetype
         ,a.endcasedate
         ,b.realpaytime
  from   prplrecase a
  join   lzm_end_pay_paid b
  on     a.Claimno = b.Claimno
  where  greatest(a.endcasedate,b.realpaydate) between trunc(date'2016-04-30','yy') and date'2016-04-30'
  and    a.recancelflag = '01'
  and    substr(a.claimno,2,1) = 'D';

-- 6 特殊案件（注销，拒赔，零结案）
-- 6.1 注销，拒赔
create table lzm_end_claim_special
(
  claimno  VARCHAR2(22),
  flag     VARCHAR2(2),
  casetype VARCHAR2(10)
);

insert into lzm_end_claim_special
  select distinct  
         b.claimno
         ,nvl(trim(substr(C.Flag, 4, 1)), '0') as flag
         ,decode(b.casetype,'0','注销','1','拒赔') as casetype
  from   prplvirtualclaim b
  left join
         prplcompensate c
  on     b.claimno = c.claimno
  and    c.recancelflag is null
  where  b.validstatus in ('8','7')
  and    b.recancelflag in ('71','81')
  and    b.casetype in ('0','1')
  and    b.canceldate between trunc(date'2016-04-30','yy') and date'2016-04-30'
  and    substr(b.claimno,2,1) = 'D'
  union
  select distinct  
         a.claimno
         ,nvl(trim(substr(C.Flag, 4, 1)), '0') as flag
         ,decode(a.casetype,'0','注销','1','拒赔') as casetype
  from   prplclaim a
  left join
         prplcompensate c
  on     a.claimno = c.claimno
  and    c.recancelflag is null
  where  a.casetype in ('0','1')
  and    a.recancelflag is null
  and    a.endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30'
  and    a.classcode = 'D';
commit;
  

-- 6.2 零结案
insert into lzm_end_claim_special
  select Claimno,
         flag,
         '零结案' as casetype
  from   (
          select 
                 B.Claimno,
                 nvl(trim(substr(C.Flag, 4, 1)), '0') as flag,
                 sum(nvl(C.Sumdutypaid, 0)) as Sumdutypaid
          from   prplclaim B
          left outer join
                 prplcompensate C
          on     B.Claimno = C.Claimno
          and    c.underwriteflag in ('1','3')
          and    c.recancelflag is null
          where  b.recancelflag is null --剔除重开案
          and    b.classcode = 'D'
          and    B.Endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30'
          and not exists (select 'X' from lzm_end_claim_special t where b.claimno = t.claimno)
          group by
                 B.Claimno,
                 nvl(trim(substr(C.Flag, 4, 1)), '0')
  )
  where  Sumdutypaid = 0;
commit;

-- 6.3 重开前零结案
insert into lzm_end_claim_special
  select Claimno,
         flag,
         '零结案'
  from   (
          select 
                 B.Claimno,
                 nvl(trim(substr(C.Flag, 4, 1)), '0') as flag,
                 sum(nvl(C.Sumdutypaid, 0)) as Sumdutypaid
          from   prplrecase B
          left outer join
                 prplcompensate C
          on     B.Claimno = C.Claimno
          and    c.recancelflag is null
          and    c.underwriteflag in ('1','3')
          where  b.recancelflag = '01'
          and    substr(b.claimno,2,1) = 'D'
          and    B.Endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30'
          and not exists (select 'X' from lzm_end_claim_special t where b.claimno = t.claimno)
          group by
                 B.Claimno,
                 nvl(trim(substr(C.Flag, 4, 1)), '0')
  )
  where  Sumdutypaid = 0;
commit;
  
-- 7 合并案件
create table lzm_end_claim_all
as
  select a.claimno,a.flag,a.casetype,b.endcasedate,null as realpaytime
  from   lzm_end_claim_special a
  join   prplclaim b
  on     a.claimno = b.claimno
  UNION ALL
  select c.claimno,c.flag,c.casetype,c.endcasedate,c.realpaytime
  from   lzm_end_claim_normal c
  left outer join
         lzm_end_claim_special d
  on     c.Claimno = d.Claimno and c.Flag = d.Flag
  where  d.claimno is null;


  
-- 8 将有估损无计算书的案件插入合并案件中
insert into lzm_end_claim_all
  select distinct 
         a.claimno
         ,decode(a.kindcode,'BZ','1','0') as flag
         ,decode(c.casetype,'0','注销','1','拒赔','零结案') as casetype
         ,c.endcasedate
         ,null as realpaytime
  from   prplclaimloss a
  join   (select distinct claimno from lzm_end_claim_all where endcasedate between trunc(date'2016-04-30','yy') and date'2016-04-30')b
  on     a.claimno = b.claimno
  join   prplclaim c
  on     a.claimno = c.claimno
  where not exists (select 'x' from lzm_end_claim_all c where a.claimno = c.claimno and decode(a.kindcode,'BZ','1','0') = c.flag)
  and not exists (select 'x' from lzm_end_pay_claimno_1 d where a.claimno = d.claimno and decode(a.kindcode,'BZ','1','0') = d.flag);
commit;


-- 9 案件基础信息
create table lzm_end_claim
as
  select b.claimno
         ,b.flag
         ,b.realpaytime
         ,a.claimdate
         ,a.endcasedate
         ,a.riskcode
         ,a.policyno
         ,a.registno
         ,b.casetype
         ,a.comcode
         ,case
             when c.comcode2 = '21010000' then '辽宁（不含大连）'
             when c.comcode2 = '21020000' then '大连'
             when c.comcode2 = '33010000' then '浙江（不含宁波）'
             when c.comcode2 = '33020000' then '宁波'
             when c.comcode2 = '35010000' then '福建（不含厦门）'
             when c.comcode2 = '35020000' then '厦门'
             when c.comcode2 = '37010000' then '山东（不含青岛）'
             when c.comcode2 = '37020000' then '青岛'
             when c.comcode2 = '44010000' then '广东（不含深圳）'
             when c.comcode2 = '44030000' then '深圳'
             else c.comname1
          end as 地区
  from   prplclaim a
  join   lzm_end_claim_all b
  on     a.claimno = b.claimno
  left join
         dimcompany c
  on     a.comcode = c.comcode;
  
-- 10 理赔金额（不包含费用）
create table lzm_end_claim_sumdutypaid
as
  select /*+ parallel(a 8)*/
         a.claimno
         ,a.flag
         ,max(b.underwriteenddate) as underwriteenddate
         ,nvl(sum(nvl(b.sumdutypaid,0)),0) as sumdutypaid
  from   lzm_end_claim a
  left join
         prplcompensate b
  on     a.claimno = b.claimno
  and    nvl(trim(substr(b.Flag, 4, 1)), '0') = a.flag
  and    b.recancelflag is null
  and    b.underwriteflag in ('1','3')
  group by
        a.claimno
         ,a.flag;
         
-- 11 投保人类型
create table lzm_end_claim_toubaoren
as
  select 
         distinct a.policyno,decode(a.insuredtype,'1','个人','2','团体') as 投保人类型
  from   prpcinsured a
  join   lzm_end_claim b
  on     a.policyno = b.policyno
  where  a.insuredflag = '2';
  
-- 12 盗抢险案件
create table lzm_end_claim_cgg1
as
  select distinct b.claimno,b.flag
  from   prplcompensate a
  join   lzm_end_claim b
  on     a.claimno = b.claimno
  and    nvl(trim(substr(a.Flag, 4, 1)), '0') = b.flag
  join   prplloss c
  on     a.compensateno = c.compensateno
  and    c.kindcode in ('G', 'G1');
  
-- 13 重开案
create table lzm_end_claim_recase
as
  select claimno,max(opencasedate) as opencasedate,min(endcasedate) as endcasedate
  from   (
          select /*+parallel(a 8)*/a.claimno,a.opencasedate,a.endcasedate
          from   prplrecase a
          where exists (select 'X' from lzm_end_claim b where b.claimno = a.claimno)
          union
          select /*+parallel(a1 8)*/a1.claimno,a1.claimcanceldate as opencasedate,a1.endcasedate
          from   prplvirtualclaim a1
          where  a1.validstatus in ('8','7')
          and exists (select 'X' from lzm_end_claim b where b.claimno = a1.claimno)
         )
  group by claimno;

--14 查勘员
create table lzm_end_claim_handler
as
  select businessno
         ,handlercode
         ,handlername
  from
         (
          select businessno
                 ,handlercode
                 ,handlername
                 ,row_number() over(partition by businessno order by flowintime desc) as rn
          from
                 (
                  select a.businessno
                         ,a.handlercode
                         ,a.handlername
                         ,a.flowintime
                  from   swflogstore a
                  where exists (select 'x' from lzm_end_claim b where a.businessno = b.registno)
                  and    a.nodename = '查勘'
                  union
                  select a.businessno
                         ,a.handlercode
                         ,a.handlername
                         ,a.flowintime
                  from   swflog a
                  where exists (select 'x' from lzm_end_claim b where a.businessno = b.registno)
                  and    a.nodename = '查勘'
                 )
         )
  where  rn = 1;

-- 15 结案清单
create table lzm_end_claim_list
as
  select 
         a.policyno as 保单号
         ,a.claimno as 立案号
         ,a.riskcode as 险种代码
         ,a.flag
         ,decode(a.flag,'1','交强险','0','商业险') as 险类
         ,to_date(to_char(d.Reportdate, 'yyyy-mm-dd') || ' ' || d.Reporthour, 'yyyy-mm-dd hh24:mi:ss') as 报案时间
         ,a.claimdate as 立案时间
         ,nvl(e.endcasedate,a.endcasedate) as 结案时间
         ,a.realpaytime as 支付时间
         ,case when b.sumdutypaid <= 10000 
                 and b.sumdutypaid > 0
                 and a.casetype not in ('0','1')
               then '是' 
               else '否' 
          end as 结案金额是否万元以下
         ,nvl(b.sumdutypaid,0) as 结案金额
         ,a.casetype as 已决赔案类型
         ,c.投保人类型
         ,e.opencasedate as 重开时间
         ,case when f.claimno is null then '否' else '是' end as 是否盗抢
         ,case when e.claimno is null then '否' else '是' end as 是否重开案件
         ,a.comcode as 五级机构代码
         ,g.handlercode as 查勘员工号
         ,g.handlername as 查勘员姓名
         ,'老理赔' as 源系统
  from   lzm_end_claim a
  left join
         lzm_end_claim_sumdutypaid b
  on     a.claimno = b.claimno
  and    a.flag = b.flag
  left join
         lzm_end_claim_toubaoren c
  on     a.policyno = c.policyno
  left join
         prplregist d
  on     d.registno = a.registno
  left join
         lzm_end_claim_recase e
  on     a.claimno = e.claimno
  left join
         lzm_end_claim_cgg1 f
  on     a.claimno = f.claimno
  and    a.flag = f.flag
  left join
         lzm_end_claim_handler g
  on     a.registno = g.businessno;

-- 16 批赔案件，结案清单需要删除的部分
drop table lzm_pipei1;
drop table lzm_pipei2;
drop table lzm_pipei3;


create table lzm_pipei1
as
select a.立案号,a.立案时间,a.结案时间,b.underwriteenddate,b.compensateno,c.realpaydate
from   lzm_END_CLAIM_LIST a
join   PRPLCOMPENSATE b
on     a.立案号 = b.claimno
and    b.underwriteflag in ('1','3')
join   lzm_end_pay_claimno_2 c
on     b.compensateno = c.compensateno
and    b.casetype = '8';

create table lzm_pipei2 as 
select b.claimno,b.endcasedate,a.*
from   lzm_pipei1 a,prplclaim b
where  a.立案号 = b.claimno 
and    b.recancelflag is null 
and    a.结案时间 = a.realpaydate
union all
select b.claimno,c.endcasedate,a.*
from   lzm_pipei1 a,prplclaim b,prplrecase c
where  a.立案号 = b.claimno 
and    b.claimno = c.claimno 
and    b.recancelflag is not null
and    c.recancelflag ='01' 
and    a.结案时间 = a.realpaydate;

create table lzm_pipei3
as
select a.claimno,nvl(trim(substr(b.Flag, 4, 1)), '0') as flag
       ,max(to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' ||c.Transtime, 'yyyy-mm-dd hh24:mi:ss')) as realpaytime
from lzm_pipei2 a
join PRPLCOMPENSATE b
on   a.claimno = b.claimno
and  b.casetype <> '8'
and  b.recancelflag is null
and  b.underwriteflag in ('1','3')
join prpjrefrechis c
on   b.compensateno = c.certino
where endcasedate>=trunc(date'2016-04-30','yy')
group by a.claimno,nvl(trim(substr(b.Flag, 4, 1)), '0');

--------------------------------------------
delete from lzm_end_claim_list a
where a.立案号 in (select distinct claimno from lzm_pipei2 where endcasedate<trunc(date'2016-04-30','yy'));
commit;

update lzm_END_CLAIM_LIST a
set a.结案时间 = (select b.realpaytime from lzm_pipei3 b where b.claimno = a.立案号 
    and a.flag = b.flag and a.结案时间 is not null and trunc(b.realpaytime) >= trunc(date'2016-04-30','yy'))
where exists (select 1 from lzm_pipei3 b where b.claimno = a.立案号 
    and a.flag = b.flag and a.结案时间 is not null and trunc(b.realpaytime) >= trunc(date'2016-04-30','yy'));
commit;

delete from lzm_END_CLAIM_LIST t
where  t.支付时间 is null
and t.已决赔案类型 = '正常结案';
commit;


--------------------------------------------------------------------------------------------
--****************         新理赔           *****************--
--------------------------------------------------------------------------------------------
--新理赔结案
drop table lzm_new_pay_claimno_1;
drop table lzm_new_pay_claimno_2;
drop table lzm_new_pay_paid;
drop table lzm_new_claim_normal;
drop table lzm_new_claim_special;
drop table lzm_new_claim_all;
drop table lzm_new_end_claim;
drop table lzm_new_claim_sumdutypaid;
drop table lzm_new_end_claim_toubaoren;
drop table lzm_new_end_claim_cgg1;
drop table lzm_new_end_checker;
drop table lzm_new_end_claim_recase;

-- 1 未支付计算书对应的立案
create table lzm_new_pay_claimno_1
as
  select /*+ parallel(A 8) */
         A.Claimno
  from   prplcompensate A
  join   prpjplanfee B
  on     A.Compensateno = B.Certino
  where  a.underwriteflag in ('1','3')
  and    a.validstatus is null
  group by A.Claimno, decode(a.COMPENSATETYPE,'1','1','0')
  having sum(B.RealPayRefFee) - sum(B.planfee1) < 0;

insert into lzm_new_pay_claimno_1
select /*+ parallel(A 8) */
         A.Claimno
  from   prplcompensate A
  join   PRPLPAYINFOLIST C
  on     a.Compensateno = C.Compensateno
  join   prpjplanfee B
  on    c.payid = B.Certino
  where  a.underwriteflag in ('1','3')
  and    a.validstatus is null
  group by A.Claimno, decode(a.COMPENSATETYPE,'1','1','0')
  having sum(B.RealPayRefFee) - sum(B.planfee1) < 0;
commit;
  
-- 2 统计期初之后的支付信息
create table lzm_new_pay_claimno_2
as
  select 
         A.Claimno, A.Compensateno, c.Realpaydate,c.Transtime
  from   prplcompensate A
  join   PRPLPAYINFOLIST b
  on     a.Compensateno = b.Compensateno
  join   PrpJrefRec c
  on     b.payid = c.Certino
  where  c.Realpaydate > trunc(date'2016-04-30','yy')-1
  and    a.recancelflag is null
  and    a.underwriteflag in ('1','3')
  and    a.validstatus is null
  UNION ALL
  select 
         A.Claimno, A.Compensateno, c.Realpaydate, c.Transtime
  from   prplcompensate A
  join   PRPLPAYINFOLIST b
  on     a.Compensateno = b.Compensateno
  join   PrpJrefRechis c
  on     b.payid = c.Certino
  where  c.Realpaydate > trunc(date'2016-04-30','yy')-1
  and    a.recancelflag is null
  and    a.underwriteflag in ('1','3')
  and    a.validstatus is null;

-- 3 统计期内支付完成的案件
create table lzm_new_pay_paid
as
  select *
  from   (
          select Claimno, Realpaydate,realpayTime
          from   (
                  select /*+ parallel(A 8) */
                         A.Claimno, A.Realpaydate, A.Transtime,
                         to_date(to_char(A.Realpaydate, 'yyyy-mm-dd') || ' ' || A.Transtime, 'yyyy-mm-dd hh24:mi:ss') as realpayTime,
                         row_number() over(partition by A.Claimno order by to_date(to_char(A.Realpaydate, 'yyyy-mm-dd') || ' ' || A.Transtime, 'yyyy-mm-dd hh24:mi:ss') desc) as rn
                  from   lzm_new_pay_claimno_2 A
                  where not exists (select 1 from lzm_new_pay_claimno_1 b where a.claimno = b.claimno)
                 )
          where  rn = 1
         )
  where  Realpaydate between trunc(date'2016-04-30','yy') and date'2016-04-30';
  
  
-- 4 圈定统计期内已决立案
create table lzm_new_claim_normal
as
  select a.claimno
         ,'正常结案' as casetype
         ,b.realpaytime
  from   prplclaim a
  join   lzm_new_pay_paid b
  on     a.Claimno = b.Claimno
  where  greatest(trunc(a.endcasedate),b.realpaydate) between trunc(date'2016-04-30','yy') and date'2016-04-30'
  and    a.recancelflag is null
  union
  select distinct 
         a.claimno
         ,'正常结案' as casetype
         ,b.realpaytime
  from   prplrecase a
  join   lzm_new_pay_paid b
  on     a.Claimno = b.Claimno
  where  greatest(trunc(a.endcasedate),b.realpaydate) between trunc(date'2016-04-30','yy') and date'2016-04-30'
  and   a.flag ='1';

--5 特殊案件（注销，拒赔）
create table lzm_new_claim_special
(
  claimno  VARCHAR2(22),
  casetype VARCHAR2(10)
);

insert into lzm_new_claim_special
  select distinct
         a.claimno
         ,decode(a.casetype,'0','注销','1','拒赔') as casetype
  from   prplclaim a
  left join
         prplcompensate c
  on     a.claimno = c.claimno
  and    c.recancelflag is null
  where  a.casetype in ('0','1')
  and    a.recancelflag is null
  and    trunc(a.endcasedate) between trunc(date'2016-04-30','yy') and date'2016-04-30';
commit;

-- 6 特殊案件（零结案）
insert into lzm_new_claim_special
  select Claimno
         ,'零结案' as casetype
  from   (
          select /*+ full(B) full(C) parallel(B 8) */
                 B.Claimno
                 ,sum(nvl(C.Sumdutypaid, 0)) as Sumdutypaid
          from   prplclaim B
          left outer join
                 prplcompensate C
          on     B.Claimno = C.Claimno
          and    c.underwriteflag in ('1','3')
          and    c.validstatus is null
          where  b.recancelflag is null --剔除重开案
          and    trunc(B.Endcasedate) between trunc(date'2016-04-30','yy') and date'2016-04-30'
          and not exists (select 1 from lzm_new_claim_special t where b.claimno = t.claimno)
          group by
                 B.Claimno
  )
  where  Sumdutypaid = 0;
commit;

-- 重开前零结案
insert into lzm_new_claim_special
  select Claimno
         ,'零结案' as casetype
  from   (
          select /*+ full(B) full(C) parallel(B 8) */
                 B.Claimno
                 ,sum(nvl(C.Sumdutypaid, 0)) as Sumdutypaid
          from   prplrecase B
          left outer join
                 prplcompensate C
          on     B.Claimno = C.Claimno
          and    c.recancelflag is null
          and    c.underwriteflag in ('1','3')
          and    c.validstatus is null
          where  b.recancelflag = '0'
          and    b.flag ='1'
          and    trunc(B.Fendcasedate) between trunc(date'2016-04-30','yy') and date'2016-04-30'
          and not exists (select 'X' from lzm_new_claim_special t where b.claimno = t.claimno)
          group by
                 B.Claimno,
                 decode(b.Opencasetype,'01','1','0')
  )
  where  Sumdutypaid = 0;
commit;

-- 7 合并案件
create table lzm_new_claim_all
as
  select a.claimno
         ,a.casetype
         ,null as realpaytime
  from   lzm_new_claim_special a
  join   prplclaim b
  on     a.claimno = b.claimno
  UNION ALL
  select b.claimno,b.casetype,b.realpaytime
  from   lzm_new_claim_normal b
  left outer join
         lzm_new_claim_special c
  on     b.Claimno = c.Claimno
  where  c.claimno is null;
  
-- 8 案件基础信息
create table lzm_new_end_claim
as
  select b.claimno
         ,a.damageflag
         ,b.realpaytime
         ,a.claimdate
         ,a.endcasedate
         ,a.riskcode
         ,a.policyno
         ,a.registno
         ,b.casetype
         ,c.comcode
         ,c.reportdate
         ,c.reporthour
         ,case
             when d.comcode2 = '21010000' then '辽宁（不含大连）'
             when d.comcode2 = '21020000' then '大连'
             when d.comcode2 = '33010000' then '浙江（不含宁波）'
             when d.comcode2 = '33020000' then '宁波'
             when d.comcode2 = '35010000' then '福建（不含厦门）'
             when d.comcode2 = '35020000' then '厦门'
             when d.comcode2 = '37010000' then '山东（不含青岛）'
             when d.comcode2 = '37020000' then '青岛'
             when d.comcode2 = '44010000' then '广东（不含深圳）'
             when d.comcode2 = '44030000' then '深圳'
             else d.comname1
          end as 地区
  from   prplclaim a
  join   lzm_new_claim_all b
  on     a.claimno = b.claimno
  join   prplregist c
  on     a.registno = c.registno
  left join
         dimcompany d
  on     c.comcode = d.comcode;
  
  
-- 9 理赔金额（不包含费用）
create table lzm_new_claim_sumdutypaid
as
  select a.claimno
         ,max(b.underwriteenddate) as underwriteenddate
         ,nvl(sum(nvl(b.sumdutypaid,0)),0) as sumdutypaid
  from   lzm_new_end_claim a
  left join
         prplcompensate b
  on     a.claimno = b.claimno
  and    b.recancelflag is null
  and    b.underwriteflag in ('1','3')
  and    b.validstatus is null
  group by
        a.claimno;
         
-- 10 投保人类型
create table lzm_new_end_claim_toubaoren
as
  select distinct a.policyno,decode(a.insuredtype,'1','个人','2','团体') as 投保人类型
  from   prpcinsured a
  join   lzm_new_end_claim b
  on     a.policyno = b.policyno
  where  a.insuredflag = '2';
  
-- 11 盗抢险案件
create table lzm_new_end_claim_cgg1
as
  select distinct b.claimno
  from   prplcompensate a
  join   lzm_new_end_claim b
  on     a.claimno = b.claimno
  join   prplloss c
  on     a.compensateno = c.compensateno
  and    c.kindcode in ('G', 'G1');
  
-- 12 重开案
create table lzm_new_end_claim_recase
as
  select claimno,max(opencasedate) as opencasedate,min(a.fendcasedate) as endcasedate
  from   prplrecase a
  where exists (select 'X' from lzm_new_end_claim b where b.claimno = a.claimno)
  and   a.flag ='1'
  group by claimno;
  
-- 13 查勘员
create table lzm_new_end_checker
as
  select a.claimno
         ,c.checkercode
         ,c.checkername 
  from   lzm_new_end_claim a
  join   prplaccidentcaserelated b
  on     a.registno = b.registno
  join   prplaccidentcheck c
  on     b.accidentno = c.accidentno;

-- 14 插入新理赔结案清单
insert into lzm_end_claim_list
  select a.policyno as 保单号
         ,a.claimno as 立案号
         ,a.riskcode as 险种代码
         ,decode(a.damageflag,'CI','1','0') as flag
         ,decode(a.damageflag,'CI','交强险','商业险') as 险类
         ,to_date(to_char(a.Reportdate, 'yyyy-mm-dd') || ' ' || a.Reporthour, 'yyyy-mm-dd hh24:mi:ss') as 报案时间
         ,a.claimdate as 立案时间
         ,nvl(d.endcasedate,a.endcasedate) as 结案时间
         ,a.realpaytime as 支付时间
         ,case when b.sumdutypaid <= 10000 
                 and b.sumdutypaid > 0
                 and a.casetype not in ('0','1')
               then '是' 
               else '否' 
          end as 结案金额是否万元以下
         ,nvl(b.sumdutypaid,0) as 结案金额
         ,a.casetype as 已决赔案类型
         ,c.投保人类型
         ,d.opencasedate as 重开时间
         ,case when e.claimno is null then '否' else '是' end as 是否盗抢
         ,case when d.claimno is null then '否' else '是' end as 是否重开案件
         ,a.comcode as 五级机构代码
         ,f.checkercode as 查勘员工号
         ,f.checkername as 查勘员姓名
         ,'新理赔' as 源系统
  from   lzm_new_end_claim a
  left join
         lzm_new_claim_sumdutypaid b
  on     a.claimno = b.claimno
  left join
         lzm_new_end_claim_toubaoren c
  on     a.policyno = c.policyno
  left join
         lzm_new_end_claim_recase d
  on     a.claimno = d.claimno
  left join
         lzm_new_end_claim_cgg1 e
  on     a.claimno = e.claimno
  left join
         lzm_new_end_checker f
  on     a.claimno = f.claimno;
commit;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               