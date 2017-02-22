--第1项清单
select 立案号
       ,查勘员工号
       ,机构代码
       ,报案日期
       ,支付日期
       ,源系统
from
(
select a.claimno as 立案号
       ,c.handlercode as 查勘员工号
       ,b.comcode as 机构代码
       ,a.reportdate as 报案日期
       ,a.realpaydate as 支付日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_end_r10000_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '查勘'
)t
where t.rn = 1
union all
select a.claimno as 立案号
       ,d.checkercode as 查勘员工号
       ,e.comcode as 机构代码
       ,a.reportdate as 报案日期
       ,a.realpaydate as 支付日期
       ,'新理赔' as 源系统
from   lzm_end_r10000_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
join   prplregist e
on     e.registno = b.registno;

--第2项清单
select 立案号
       ,查勘员工号
       ,机构代码
       ,报案日期
       ,支付日期
       ,源系统
from
(
select a.claimno as 立案号
       ,c.handlercode as 查勘员工号
       ,b.comcode as 机构代码
       ,a.reportdate as 报案日期
       ,a.realpaydate as 支付日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_end_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '查勘'
)t
where t.rn = 1
union all
select a.claimno as 立案号
       ,d.checkercode as 查勘员工号
       ,e.comcode as 机构代码
       ,a.reportdate as 报案日期
       ,a.realpaydate as 支付日期
       ,'新理赔' as 源系统
from   lzm_end_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
join   prplregist e
on     e.registno = b.registno;

--第3项清单
select 立案号
       ,查勘员工号
       ,机构代码
       ,结案日期
       ,源系统
from
(
select a.claimno as 立案号
       ,b.handlercode as 查勘员工号
       ,a.comcode as 机构代码
       ,a.endcasedate as 结案日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflogstore b
on     b.businessno = a.registno
and    b.nodename = '查勘'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
)t
where t.rn = 1
union all
select 立案号
       ,查勘员工号
       ,机构代码
       ,结案日期
       ,源系统
from
(
select a.claimno as 立案号
       ,b.handlercode as 查勘员工号
       ,a.comcode as 机构代码
       ,a.endcasedate as 结案日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflog b
on     b.businessno = a.registno
and    b.nodename = '查勘'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
)t
where t.rn = 1
union all
select a.claimno as 立案号
       ,d.checkercode as 查勘员工号
       ,b.comcode as 机构代码
       ,a.endcasedate as 结案日期
       ,'新理赔' as 源系统
from   prplclaim a
join   prplregist b
on     a.registno = b.registno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
where  b.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate >= add_months(date'2016-03-31', -12) + 1
and    a.claimdate < date'2016-03-31' + 1;

--第4项清单
select 立案号
       ,查勘员工号
       ,机构代码
       ,最终核损完成日期
       ,报案日期
       ,源系统
from
(
select a.claimno as 立案号
       ,c.handlercode as 查勘员工号
       ,b.comcode as 机构代码
       ,a.Underwriteenddate as 最终核损完成日期
       ,a.Reportdate as 报案日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_verif_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '查勘'
)t
where t.rn = 1
union all
select 立案号
       ,查勘员工号
       ,机构代码
       ,最终核损完成日期
       ,报案日期
       ,源系统
from
(
select a.claimno as 立案号
       ,c.handlercode as 查勘员工号
       ,b.comcode as 机构代码
       ,a.Underwriteenddate as 最终核损完成日期
       ,a.Reportdate as 报案日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_verif_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflog c
on     c.businessno = b.registno
and    c.nodename = '查勘'
)t
where t.rn = 1
union all
select a.claimno as 立案号
       ,d.checkercode as 查勘员工号
       ,e.comcode as 机构代码
       ,a.verifyenddate as 最终核损完成日期
       ,a.reportdate as 报案日期
       ,'新理赔' as 源系统
from   lzm_verif_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
join   prplregist e
on     e.registno = b.registno;

--第6项清单
select 立案号
       ,查勘员工号
       ,机构代码
       ,立案日期
       ,源系统
from
(
select a.claimno as 立案号
       ,b.handlercode as 查勘员工号
       ,a.comcode as 机构代码
       ,a.claimdate as 立案日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflogstore b
on     b.businessno = a.registno
and    b.nodename = '查勘'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between trunc(date'2016-03-31', 'yy') and date'2016-03-31'
)t
where t.rn = 1
union all
select 立案号
       ,查勘员工号
       ,机构代码
       ,立案日期
       ,源系统
from
(
select a.claimno as 立案号
       ,b.handlercode as 查勘员工号
       ,a.comcode as 机构代码
       ,a.claimdate as 立案日期
       ,'老理赔' as 源系统
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflog b
on     b.businessno = a.registno
and    b.nodename = '查勘'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between trunc(date'2016-03-31', 'yy') and date'2016-03-31'
)t
where t.rn = 1
union all
select a.claimno as 立案号
       ,d.checkercode as 查勘员工号
       ,b.comcode as 机构代码
       ,a.claimdate as 立案日期
       ,'新理赔' as 源系统
from   prplclaim a
join   prplregist b
on     a.registno = b.registno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
where  b.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate >= trunc(date'2016-03-31', 'yy')
and    a.claimdate < date'2016-03-31' + 1;


--第7项分母
select 报案号,立案号,查勘员工号,机构代码
from
       (
       select a.registno as 报案号
              ,a.claimno as 立案号
              ,b.handlercode as 查勘员工号
              ,c.comcode as 机构代码
              ,row_number() over(partition by a.registno order by b.flowintime desc) as rn
       from
              (
              select registno,null as claimno from alan_jy_unclaim_3501_last
              union all
              select registno,claimno from alan_jy_unend_3501_last
              union all
              select registno,claimno from alan_jy_end_claim_3501_last
              )a
       join   swflogstore b
       on     b.businessno = a.registno
       and    b.nodename = '查勘'
       join   prplregist c
       on     a.registno = c.registno
       )t
where  t.rn = 1
union all
select 报案号,立案号,查勘员工号,机构代码
from
       (
       select a.registno as 报案号
              ,a.claimno as 立案号
              ,b.handlercode as 查勘员工号
              ,c.comcode as 机构代码
              ,row_number() over(partition by a.registno order by b.flowintime desc) as rn
       from
              (
              select registno,null as claimno from alan_jy_unclaim_3501_last
              union all
              select registno,claimno from alan_jy_unend_3501_last
              union all
              select registno,claimno from alan_jy_end_claim_3501_last
              )a
       join   swflog b
       on     b.businessno = a.registno
       and    b.nodename = '查勘'
       join   prplregist c
       on     a.registno = c.registno
       )t
where  t.rn = 1
union all
select a.registno as 报案号
       ,a.claimno as 立案号
       ,c.checkercode as 查勘员工号
       ,d.comcode as 机构代码
from
      (
      select registno,null as claimno from lzm_jy_unclaim_3501_last
      union
      select registno,claimno from lzm_jy_unend_3501_last
      union
      select registno,claimno from lzm_jy_end_claim_3501_last
      )a
left join
       prplaccidentcaserelated b
on     b.registno = a.registno
left join
       prplaccidentcheck c
on     b.accidentno = c.accidentno
left join
       prplregist d
on     a.registno = d.registno;

--第7项分子
select 报案号,立案号,查勘员工号,机构代码
from
       (
       select a.registno as 报案号
              ,a.claimno as 立案号
              ,b.handlercode as 查勘员工号
              ,c.comcode as 机构代码
              ,row_number() over(partition by a.registno order by b.flowintime desc) as rn
       from   (
                select *
                from   (
                select registno,null as claimno from alan_jy_unclaim_3501_last
                union all
                select registno,claimno from alan_jy_unend_3501_last
                union all
                select registno,claimno from alan_jy_end_claim_3501_last
                       )
                minus
                select *
                from   (
                select registno,null as claimno from alan_jy_unclaim_3501_this
                union all
                select registno,claimno from alan_jy_unend_3501_this
                union all
                select registno,claimno from alan_jy_end_claim_3501_this
                       )
               ) a
       join   swflogstore b
       on     b.businessno = a.registno
       and    b.nodename = '查勘'
       join   prplregist c
       on     a.registno = c.registno
       )t
where t.rn = 1
union
select a.registno as 报案号
       ,a.claimno as 立案号
       ,c.checkercode as 查勘员工号
       ,d.comcode as 机构代码
from  (
        select *
        from   (
        select registno,null as claimno from lzm_jy_unclaim_3501_last
        union all
        select registno,claimno from lzm_jy_unend_3501_last
        union all
        select registno,claimno from lzm_jy_end_claim_3501_last
               )
        minus
        select *
        from   (
        select registno,null as claimno from lzm_jy_unclaim_3501_this
        union all
        select registno,claimno from lzm_jy_unend_3501_this
        union all
        select registno,claimno from lzm_jy_end_claim_3501_this
               )
       ) a
left join
       prplaccidentcaserelated b
on     b.registno = a.registno
left join
       prplaccidentcheck c
on     b.accidentno = c.accidentno
left join
       prplregist d
on     a.registno = d.registno;

--第8项清单
select /*+ full(a) parallel(a 8) */
      b.claimno as 立案号
      ,c.handlercode as 查勘员工号
      ,b.comcode as 机构代码
      ,a.opencasedate as 重开时间
      ,'老理赔' as 源系统
from   prplrecase a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '查勘'
where  a.opencasedate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
and    b.comcode like '3501%'
and    b.classcode = 'D'
and    b.endcasedate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
union
select /*+ full(B) full(C) parallel(l 8) */
       b.claimno as 立案号
       ,e.checkercode as 查勘员工号
       ,c.comcode as 机构代码
       ,a.opencasedate as 重开时间
       ,'新理赔' as 源系统
from   prplrecase A
join   prplclaim B
on     A.claimno = B.claimno
join   prplregist C
on     B.Registno = C.Registno
join   prplaccidentcaserelated d
on     c.registno = d.registno
join   prplaccidentcheck e
on     e.accidentno = d.accidentno
where  A.opencasedate >= add_months(date'2016-03-31', -12) + 1 
and    A.opencasedate < date'2016-03-31' + 1
and    C.Comcode like '3501%'
and    B.classcode = 'D'
and    B.endcasedate >= add_months(date'2016-03-31', -12) + 1
and    B.endcasedate < date'2016-03-31' + 1;
