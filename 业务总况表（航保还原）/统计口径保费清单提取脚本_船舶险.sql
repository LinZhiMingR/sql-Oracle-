--01 圈定保单和批单
drop table lzm_fujian_hangbaohuanyuan_pre;
create table lzm_fujian_hangbaohuanyuan_pre
(保单号 varchar(255),
批单号 varchar(255),
险类代码 varchar(255),
险种代码 varchar(255),
投保人名称 varchar(255),
被保险人名称 varchar(255),
起保日期 date,
终保日期 date,
统计日期 date,
机构代码 varchar(255),
归属业务员代码 varchar(255),
共保标志 varchar(255),
币别 varchar(255),
保额 number,
保费 number
);

insert into lzm_fujian_hangbaohuanyuan_pre
  select a.policyno as 保单号
         ,null as 批单号
         ,a.classcode as 险类代码
         ,a.riskcode as 险种代码
         ,a.appliname as 投保人名称
         ,a.insuredname as 被保险人名称
         ,a.startdate as 起保日期
         ,a.enddate as 终保日期
         ,a.statdate as 统计日期
         ,nvl(b.mappingcomcode,a.comcode) as 机构代码
         ,a.Handler1Code as 归属业务员代码
         ,a.CoinsFlag as 共保标志
         ,a.currency as 币别
         ,A.cnySumamount * A.Coinsrate / 100 as 保额
         ,A.cnySumpremium * A.Coinsrate / 100 as 保费
  from   cgcmain A
  left join
         cgdmccommapping b
  on     a.comcode = b.comcode
  where  A.Statdate between date'2015-01-01' and date'2016-06-02'--替换日期
  and    (A.Statflag = 'Y' or A.Statflag is null)
  and    a.classcode = 'C'
  and    A.cnySumpremium * A.Coinsrate / 100 <> 0
  and    (a.comcode like '3501%' or b.mappingcomcode like '3501%');
commit;

insert into lzm_fujian_hangbaohuanyuan_pre
  select a.policyno as 保单号
         ,a.endorseno as  批单号
         ,a.classcode as 险类代码
         ,a.riskcode as 险种代码
         ,a.appliname as 投保人名称
         ,a.insuredname as 被保险人名称
         ,a.startdate as 起保日期
         ,a.enddate as 终保日期
         ,a.statdate as 统计日期
         ,nvl(b.mappingcomcode,a.comcode) as 机构代码
         ,a.Handler1Code as 归属业务员代码
         ,a.CoinsFlag as 共保标志
         ,a.currency as 币别
         ,A.cnychgSumamount * A.Coinsrate / 100 as 保额
         ,A.cnychgSumpremium * A.Coinsrate / 100 as 保费
  from   cgpmain A
  left join
         cgdmccommapping b
  on     a.comcode = b.comcode
  where  A.Statdate between date'2015-01-01' and date'2016-06-02'--替换日期
  and    a.classcode = 'C'
  and    (A.cnychgSumpremium * A.Coinsrate / 100 <> 0 or A.cnychgSumamount * A.Coinsrate / 100 <> 0)
  and    (a.comcode like '3501%' or b.mappingcomcode like '3501%');
commit;

--02 核保日期
drop table lzm_fujian_hangbao_underdate;
create table lzm_fujian_hangbao_underdate
as
  select a.policyno as 保单号
         ,a.underwriteenddate as 核保日期
  from   cgcmain a
  where exists (select 'X' from lzm_fujian_hangbaohuanyuan_pre b where b.保单号 = a.policyno);

--03 船名
drop table lzm_fujian_hangbao_ShipCName;
create table lzm_fujian_hangbao_ShipCName
as
  select t.保单号
         ,t.船名
  from
         (
         select a.policyno as 保单号
                ,a.ShipCName as 船名
                ,row_number() over(partition by a.policyno order by a.ItemNo desc) as rn
         from   PrpCitemShip@ccicdb a
         where exists (select 'X' from lzm_fujian_hangbaohuanyuan_pre b where b.保单号 = a.policyno)
         )t
  where t.rn = 1;

--04 提取结果
drop table lzm_fujian_hangbaohuanyuan;
create table lzm_fujian_hangbaohuanyuan
as
  select a.保单号
         ,a.批单号
         ,a.险类代码
         ,a.险种代码
         ,a.投保人名称
         ,a.被保险人名称
         ,a.起保日期
         ,a.终保日期
         ,b.核保日期
         ,a.统计日期
         ,a.机构代码
         ,a.归属业务员代码
         ,a.共保标志
         ,a.币别
         ,a.保额
         ,a.保费
         ,c.船名
  from   lzm_fujian_hangbaohuanyuan_pre a
  left join
         lzm_fujian_hangbao_underdate b
  on     b.保单号 = a.保单号
  left join
         lzm_fujian_hangbao_ShipCName c
  on     c.保单号 = a.保单号;