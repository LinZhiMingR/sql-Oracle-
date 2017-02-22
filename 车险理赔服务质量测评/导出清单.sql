--��1���嵥
select ������
       ,�鿱Ա����
       ,��������
       ,��������
       ,֧������
       ,Դϵͳ
from
(
select a.claimno as ������
       ,c.handlercode as �鿱Ա����
       ,b.comcode as ��������
       ,a.reportdate as ��������
       ,a.realpaydate as ֧������
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_end_r10000_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '�鿱'
)t
where t.rn = 1
union all
select a.claimno as ������
       ,d.checkercode as �鿱Ա����
       ,e.comcode as ��������
       ,a.reportdate as ��������
       ,a.realpaydate as ֧������
       ,'������' as Դϵͳ
from   lzm_end_r10000_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
join   prplregist e
on     e.registno = b.registno;

--��2���嵥
select ������
       ,�鿱Ա����
       ,��������
       ,��������
       ,֧������
       ,Դϵͳ
from
(
select a.claimno as ������
       ,c.handlercode as �鿱Ա����
       ,b.comcode as ��������
       ,a.reportdate as ��������
       ,a.realpaydate as ֧������
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_end_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '�鿱'
)t
where t.rn = 1
union all
select a.claimno as ������
       ,d.checkercode as �鿱Ա����
       ,e.comcode as ��������
       ,a.reportdate as ��������
       ,a.realpaydate as ֧������
       ,'������' as Դϵͳ
from   lzm_end_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
join   prplregist e
on     e.registno = b.registno;

--��3���嵥
select ������
       ,�鿱Ա����
       ,��������
       ,�᰸����
       ,Դϵͳ
from
(
select a.claimno as ������
       ,b.handlercode as �鿱Ա����
       ,a.comcode as ��������
       ,a.endcasedate as �᰸����
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflogstore b
on     b.businessno = a.registno
and    b.nodename = '�鿱'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
)t
where t.rn = 1
union all
select ������
       ,�鿱Ա����
       ,��������
       ,�᰸����
       ,Դϵͳ
from
(
select a.claimno as ������
       ,b.handlercode as �鿱Ա����
       ,a.comcode as ��������
       ,a.endcasedate as �᰸����
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflog b
on     b.businessno = a.registno
and    b.nodename = '�鿱'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
)t
where t.rn = 1
union all
select a.claimno as ������
       ,d.checkercode as �鿱Ա����
       ,b.comcode as ��������
       ,a.endcasedate as �᰸����
       ,'������' as Դϵͳ
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

--��4���嵥
select ������
       ,�鿱Ա����
       ,��������
       ,���պ����������
       ,��������
       ,Դϵͳ
from
(
select a.claimno as ������
       ,c.handlercode as �鿱Ա����
       ,b.comcode as ��������
       ,a.Underwriteenddate as ���պ����������
       ,a.Reportdate as ��������
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_verif_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '�鿱'
)t
where t.rn = 1
union all
select ������
       ,�鿱Ա����
       ,��������
       ,���պ����������
       ,��������
       ,Դϵͳ
from
(
select a.claimno as ������
       ,c.handlercode as �鿱Ա����
       ,b.comcode as ��������
       ,a.Underwriteenddate as ���պ����������
       ,a.Reportdate as ��������
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by c.flowintime desc) as rn
from   alan_verif_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   swflog c
on     c.businessno = b.registno
and    c.nodename = '�鿱'
)t
where t.rn = 1
union all
select a.claimno as ������
       ,d.checkercode as �鿱Ա����
       ,e.comcode as ��������
       ,a.verifyenddate as ���պ����������
       ,a.reportdate as ��������
       ,'������' as Դϵͳ
from   lzm_verif_r_3501 a
join   prplclaim b
on     a.claimno = b.claimno
join   prplaccidentcaserelated c
on     b.registno = c.registno
join   prplaccidentcheck d
on     c.accidentno = d.accidentno
join   prplregist e
on     e.registno = b.registno;

--��6���嵥
select ������
       ,�鿱Ա����
       ,��������
       ,��������
       ,Դϵͳ
from
(
select a.claimno as ������
       ,b.handlercode as �鿱Ա����
       ,a.comcode as ��������
       ,a.claimdate as ��������
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflogstore b
on     b.businessno = a.registno
and    b.nodename = '�鿱'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between trunc(date'2016-03-31', 'yy') and date'2016-03-31'
)t
where t.rn = 1
union all
select ������
       ,�鿱Ա����
       ,��������
       ,��������
       ,Դϵͳ
from
(
select a.claimno as ������
       ,b.handlercode as �鿱Ա����
       ,a.comcode as ��������
       ,a.claimdate as ��������
       ,'������' as Դϵͳ
       ,row_number() over(partition by a.claimno order by b.flowintime desc) as rn
from   prplclaim a
join   swflog b
on     b.businessno = a.registno
and    b.nodename = '�鿱'
where  a.comcode like '3501%'
and    a.classcode = 'D'
and    a.claimdate between trunc(date'2016-03-31', 'yy') and date'2016-03-31'
)t
where t.rn = 1
union all
select a.claimno as ������
       ,d.checkercode as �鿱Ա����
       ,b.comcode as ��������
       ,a.claimdate as ��������
       ,'������' as Դϵͳ
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


--��7���ĸ
select ������,������,�鿱Ա����,��������
from
       (
       select a.registno as ������
              ,a.claimno as ������
              ,b.handlercode as �鿱Ա����
              ,c.comcode as ��������
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
       and    b.nodename = '�鿱'
       join   prplregist c
       on     a.registno = c.registno
       )t
where  t.rn = 1
union all
select ������,������,�鿱Ա����,��������
from
       (
       select a.registno as ������
              ,a.claimno as ������
              ,b.handlercode as �鿱Ա����
              ,c.comcode as ��������
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
       and    b.nodename = '�鿱'
       join   prplregist c
       on     a.registno = c.registno
       )t
where  t.rn = 1
union all
select a.registno as ������
       ,a.claimno as ������
       ,c.checkercode as �鿱Ա����
       ,d.comcode as ��������
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

--��7�����
select ������,������,�鿱Ա����,��������
from
       (
       select a.registno as ������
              ,a.claimno as ������
              ,b.handlercode as �鿱Ա����
              ,c.comcode as ��������
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
       and    b.nodename = '�鿱'
       join   prplregist c
       on     a.registno = c.registno
       )t
where t.rn = 1
union
select a.registno as ������
       ,a.claimno as ������
       ,c.checkercode as �鿱Ա����
       ,d.comcode as ��������
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

--��8���嵥
select /*+ full(a) parallel(a 8) */
      b.claimno as ������
      ,c.handlercode as �鿱Ա����
      ,b.comcode as ��������
      ,a.opencasedate as �ؿ�ʱ��
      ,'������' as Դϵͳ
from   prplrecase a
join   prplclaim b
on     a.claimno = b.claimno
join   swflogstore c
on     c.businessno = b.registno
and    c.nodename = '�鿱'
where  a.opencasedate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
and    b.comcode like '3501%'
and    b.classcode = 'D'
and    b.endcasedate between add_months(date'2016-03-31', -12) + 1 and date'2016-03-31'
union
select /*+ full(B) full(C) parallel(l 8) */
       b.claimno as ������
       ,e.checkercode as �鿱Ա����
       ,c.comcode as ��������
       ,a.opencasedate as �ؿ�ʱ��
       ,'������' as Դϵͳ
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
