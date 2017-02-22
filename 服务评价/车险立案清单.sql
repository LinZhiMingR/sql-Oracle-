--*****************����������***********************
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
-- 1 Ȧ��ͳ�������� 
create table lzm_claim_all
as
  select a.claimno
  from   prplclaim a
  where  a.Claimdate between trunc(date'2016-09-30','yy') and date'2016-09-30'
  and    a.classcode = 'D';
  
-- 2 �����������ҵ��ǿ
create table lzm_claim_loss
as
  select distinct
         a.claimno
         ,decode(a.kindcode,'BZ','1','0') as flag
  from   PrpLclaimLoss a
  where exists (select 'X' from lzm_claim_all b where a.claimno = b.claimno);
-- 3 ������������ҵ��ǿ
create table lzm_claim_compensate
as
  select distinct
         a.claimno
         ,nvl(trim(substr(A.Flag, 4, 1)), '0')  as flag
  from   prplcompensate a
  where exists (select 'X' from lzm_claim_all b where a.claimno = b.claimno)
  and  a.recancelflag is null
  and  a.underwriteflag in ('1','3'); 
  
-- 4 �ϲ�
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

-- 5 ����������Ϣ
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
            when c.comcode2 = '21010000' then '����������������'
            when c.comcode2 = '21020000' then '����'
            when c.comcode2 = '33010000' then '�㽭������������'
            when c.comcode2 = '33020000' then '����'
            when c.comcode2 = '35010000' then '�������������ţ�'
            when c.comcode2 = '35020000' then '����'
            when c.comcode2 = '37010000' then 'ɽ���������ൺ��'
            when c.comcode2 = '37020000' then '�ൺ'
            when c.comcode2 = '44010000' then '�㶫���������ڣ�'
            when c.comcode2 = '44030000' then '����'
            else c.comname1
         end as ����
  from   prplclaim a
  join   lzm_claim_pre b
  on     a.claimno = b.claimno
  left join
         dimcompany c
  on     a.comcode = c.comcode;
  
-- 6 Ͷ��������
create table lzm_claim_toubaoren
as
  select /*+parallel(a 8)*/distinct a.policyno,decode(a.insuredtype,'1','����','2','����') as Ͷ��������
  from   prpcinsured a
  join   lzm_claim b
  on     a.policyno = b.policyno
  where  a.insuredflag = '2';
  


-- 7 �����հ���
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
  

-- 8 �ؿ���
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

-- 9 �鿱Ա
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
                  and    a.nodename = '�鿱'
                  union
                  select a.businessno
                         ,a.handlercode
                         ,a.handlername
                         ,a.flowintime
                  from   swflog a
                  where exists (select 'x' from lzm_claim b where a.businessno = b.registno)
                  and    a.nodename = '�鿱'
                 )
         )
  where  rn = 1;
 
-- 10 �����嵥

create table lzm_claim_list
as
  select a.policyno as ������
         ,a.claimno as ������
         ,a.riskcode as ���ִ���
         ,decode(a.flag,'1','��ǿ��','0','��ҵ��') as ����
         ,to_date(to_char(e.Reportdate, 'yyyy-mm-dd') || ' ' || e.Reporthour, 'yyyy-mm-dd hh24:mi:ss') as ����ʱ��
         ,a.claimdate as ����ʱ��
         ,b.Ͷ�������� as Ͷ��������
         ,case when c.claimno is null then '��' else '��' end as �Ƿ����
         ,case when d.claimno is null then '��' else '��' end as �Ƿ��ؿ�����
         ,a.comcode as �弶��������
         ,f.handlercode as �鿱Ա����
         ,f.handlername as �鿱Ա����
         ,'������' as Դϵͳ
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
  
--*****************����������***********************
drop table lzm_new_claim;
drop table lzm_new_claim_toubaoren;
drop table lzm_new_claim_cgg1;
drop table lzm_new_claim_recase;
drop table lzm_new_claim_checker;

-- 1 Ȧ��ͳ�������� 
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
  
-- 2 Ͷ��������
create table lzm_new_claim_toubaoren
as
  select /*+parallel(a 8)*/distinct a.policyno,decode(a.insuredtype,'1','����','2','����') as Ͷ��������
  from   prpcinsured a
  join   lzm_new_claim b
  on     a.policyno = b.policyno
  where  a.insuredflag = '2';
  
-- 3 �����հ���
create table lzm_new_claim_cgg1
as
  select distinct b.claimno
  from   prplcompensate a
  join   lzm_new_claim b
  on     a.claimno = b.claimno
  join   prplloss c
  on     a.compensateno = c.compensateno
  and    c.kindcode in ('G', 'G1');
  

-- 4 �ؿ���
create table lzm_new_claim_recase
as
  select distinct a.claimno
  from   prplrecase a
  where exists (select 'X' from lzm_new_claim b where b.claimno = a.claimno)
  and a.flag='1';
  
-- 5 �鿱��
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

-- 6 ���������������嵥
insert into lzm_claim_list
  select a.policyno as ������
         ,a.claimno as ������
         ,a.riskcode as ���ִ���
         ,decode(a.damageflag,'CI','��ǿ��','��ҵ��') as ����
         ,to_date(to_char(a.Reportdate, 'yyyy-mm-dd') || ' ' || a.Reporthour, 'yyyy-mm-dd hh24:mi:ss') as ����ʱ��
         ,a.claimdate as ����ʱ��
         ,b.Ͷ�������� as Ͷ��������
         ,case when c.claimno is null then '��' else '��' end as �Ƿ����
         ,case when d.claimno is null then '��' else '��' end as �Ƿ��ؿ�����
         ,a.comcode as �弶��������
         ,e.checkercode as �鿱Ա����
         ,e.checkername as �鿱Ա����
         ,'������' as Դϵͳ
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
