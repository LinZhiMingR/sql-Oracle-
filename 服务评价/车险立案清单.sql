--*****************老理赔立案***********************
drop table lzm_claim_all;
drop table lzm_claim_loss;
drop table lzm_claim_compensate;
drop table lzm_claim_pre;
drop table lzm_claim;
drop table lzm_claim_toubaoren;
drop table lzm_claim_cgg1;
drop table lzm_claim_recase;
drop table lzm_claim_handler;
drop table lzm_claim_list;
-- 1 圈定统计期立案 
create table lzm_claim_all
as
  select a.claimno
  from   prplclaim a
  where  a.Claimdate between trunc(date'2016-09-30','yy') and date'2016-09-30'
  and    a.classcode = 'D';
  
-- 2 估损表区分商业交强
create table lzm_claim_loss
as
  select distinct
         a.claimno
         ,decode(a.kindcode,'BZ','1','0') as flag
  from   PrpLclaimLoss a
  where exists (select 'X' from lzm_claim_all b where a.claimno = b.claimno);
-- 3 计算书区分商业交强
create table lzm_claim_compensate
as
  select distinct
         a.claimno
         ,nvl(trim(substr(A.Flag, 4, 1)), '0')  as flag
  from   prplcompensate a
  where exists (select 'X' from lzm_claim_all b where a.claimno = b.claimno)
  and  a.recancelflag is null
  and  a.underwriteflag in ('1','3'); 
  
-- 4 合并
create table lzm_claim_pre
as
  select distinct 
         nvl(a.claimno,b.claimno) as claimno
         ,nvl(a.flag,b.flag) as flag
  from   lzm_claim_compensate a
  full join
         lzm_claim_loss b
  on     a.claimno = b.claimno
  and    a.flag = b.flag;

-- 5 案件基础信息
create table lzm_claim
as
  select a.claimno
         ,b.flag
         ,a.policyno
         ,a.registno
         ,a.riskcode
         ,a.claimdate
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
  join   lzm_claim_pre b
  on     a.claimno = b.claimno
  left join
         dimcompany c
  on     a.comcode = c.comcode;
  
-- 6 投保人类型
create table lzm_claim_toubaoren
as
  select /*+parallel(a 8)*/distinct a.policyno,decode(a.insuredtype,'1','个人','2','团体') as 投保人类型
  from   prpcinsured a
  join   lzm_claim b
  on     a.policyno = b.policyno
  where  a.insuredflag = '2';
  


-- 7 盗抢险案件
create table lzm_claim_cgg1
as
  select distinct b.claimno,b.flag
  from   prplcompensate a
  join   lzm_claim b
  on     a.claimno = b.claimno
  and    nvl(trim(substr(a.Flag, 4, 1)), '0') = b.flag
  join   prplloss c
  on     a.compensateno = c.compensateno
  and    c.kindcode in ('G', 'G1');
  

-- 8 重开案
create table lzm_claim_recase
as
  select a.claimno
  from   prplrecase a
  where exists (select 'X' from lzm_claim b where b.claimno = a.claimno)
  union
  select a1.claimno
  from   prplvirtualclaim a1
  where  a1.validstatus in ('8','7')
  and exists (select 'X' from lzm_claim b where b.claimno = a1.claimno);

-- 9 查勘员
create table lzm_claim_handler
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
                  where exists (select 'x' from lzm_claim b where a.businessno = b.registno)
                  and    a.nodename = '查勘'
                  union
                  select a.businessno
                         ,a.handlercode
                         ,a.handlername
                         ,a.flowintime
                  from   swflog a
                  where exists (select 'x' from lzm_claim b where a.businessno = b.registno)
                  and    a.nodename = '查勘'
                 )
         )
  where  rn = 1;
 
-- 10 立案清单

create table lzm_claim_list
as
  select a.policyno as 保单号
         ,a.claimno as 立案号
         ,a.riskcode as 险种代码
         ,decode(a.flag,'1','交强险','0','商业险') as 险类
         ,to_date(to_char(e.Reportdate, 'yyyy-mm-dd') || ' ' || e.Reporthour, 'yyyy-mm-dd hh24:mi:ss') as 报案时间
         ,a.claimdate as 立案时间
         ,b.投保人类型 as 投保人类型
         ,case when c.claimno is null then '否' else '是' end as 是否盗抢
         ,case when d.claimno is null then '否' else '是' end as 是否重开案件
         ,a.comcode as 五级机构代码
         ,f.handlercode as 查勘员工号
         ,f.handlername as 查勘员姓名
         ,'老理赔' as 源系统
  from   lzm_claim a
  left join
         lzm_claim_toubaoren b
  on     a.policyno = b.policyno
  left join
         lzm_claim_cgg1 c
  on     c.claimno = a.claimno
  and    c.flag = c.flag
  left join
         lzm_claim_recase d
  on     d.claimno = a.claimno
  left join
         prplregist e
  on     a.registno = e.registno
  left join
         lzm_claim_handler f
  on     a.registno = f.businessno;
  
--*****************新理赔立案***********************
drop table lzm_new_claim;
drop table lzm_new_claim_toubaoren;
drop table lzm_new_claim_cgg1;
drop table lzm_new_claim_recase;
drop table lzm_new_claim_checker;

-- 1 圈定统计期立案 
create table lzm_new_claim
as
  select a.claimno
         ,a.damageflag
         ,a.policyno
         ,a.registno
         ,a.riskcode
         ,a.claimdate
         ,b.reportdate
         ,b.reporthour
         ,b.comcode
  from   prplclaim a
  left join
         prplregist b
  on     a.registno = b.registno
  where  trunc(a.Claimdate) between trunc(date'2016-09-30','yy') and date'2016-09-30';
  
-- 2 投保人类型
create table lzm_new_claim_toubaoren
as
  select /*+parallel(a 8)*/distinct a.policyno,decode(a.insuredtype,'1','个人','2','团体') as 投保人类型
  from   prpcinsured a
  join   lzm_new_claim b
  on     a.policyno = b.policyno
  where  a.insuredflag = '2';
  
-- 3 盗抢险案件
create table lzm_new_claim_cgg1
as
  select distinct b.claimno
  from   prplcompensate a
  join   lzm_new_claim b
  on     a.claimno = b.claimno
  join   prplloss c
  on     a.compensateno = c.compensateno
  and    c.kindcode in ('G', 'G1');
  

-- 4 重开案
create table lzm_new_claim_recase
as
  select distinct a.claimno
  from   prplrecase a
  where exists (select 'X' from lzm_new_claim b where b.claimno = a.claimno)
  and a.flag='1';
  
-- 5 查勘人
create table lzm_new_claim_checker
as
  select a.claimno
         ,c.checkercode
         ,c.checkername 
  from   lzm_new_claim a
  join   prplaccidentcaserelated b
  on     a.registno = b.registno
  join   prplaccidentcheck c
  on     b.accidentno = c.accidentno;

-- 6 插入新理赔立案清单
insert into lzm_claim_list
  select a.policyno as 保单号
         ,a.claimno as 立案号
         ,a.riskcode as 险种代码
         ,decode(a.damageflag,'CI','交强险','商业险') as 险类
         ,to_date(to_char(a.Reportdate, 'yyyy-mm-dd') || ' ' || a.Reporthour, 'yyyy-mm-dd hh24:mi:ss') as 报案时间
         ,a.claimdate as 立案时间
         ,b.投保人类型 as 投保人类型
         ,case when c.claimno is null then '否' else '是' end as 是否盗抢
         ,case when d.claimno is null then '否' else '是' end as 是否重开案件
         ,a.comcode as 五级机构代码
         ,e.checkercode as 查勘员工号
         ,e.checkername as 查勘员姓名
         ,'新理赔' as 源系统
  from   lzm_new_claim a
  left join
         lzm_new_claim_toubaoren b
  on     a.policyno = b.policyno
  left join
         lzm_new_claim_cgg1 c
  on     c.claimno = a.claimno
  left join
         lzm_new_claim_recase d
  on     d.claimno = a.claimno
  left join
         lzm_new_claim_checker e
  on     e.claimno = a.claimno;
commit;
