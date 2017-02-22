--01 Ȧ������������
drop table lzm_fujian_hangbaohuanyuan_pre;
create table lzm_fujian_hangbaohuanyuan_pre
(������ varchar(255),
������ varchar(255),
������� varchar(255),
���ִ��� varchar(255),
Ͷ�������� varchar(255),
������������ varchar(255),
������ date,
�ձ����� date,
ͳ������ date,
�������� varchar(255),
����ҵ��Ա���� varchar(255),
������־ varchar(255),
�ұ� varchar(255),
���� number,
���� number
);

insert into lzm_fujian_hangbaohuanyuan_pre
  select a.policyno as ������
         ,null as ������
         ,a.classcode as �������
         ,a.riskcode as ���ִ���
         ,a.appliname as Ͷ��������
         ,a.insuredname as ������������
         ,a.startdate as ������
         ,a.enddate as �ձ�����
         ,a.statdate as ͳ������
         ,nvl(b.mappingcomcode,a.comcode) as ��������
         ,a.Handler1Code as ����ҵ��Ա����
         ,a.CoinsFlag as ������־
         ,a.currency as �ұ�
         ,A.cnySumamount * A.Coinsrate / 100 as ����
         ,A.cnySumpremium * A.Coinsrate / 100 as ����
  from   cgcmain A
  left join
         cgdmccommapping b
  on     a.comcode = b.comcode
  where  A.Statdate between date'2015-01-01' and date'2016-06-02'--�滻����
  and    (A.Statflag = 'Y' or A.Statflag is null)
  and    a.classcode = 'C'
  and    A.cnySumpremium * A.Coinsrate / 100 <> 0
  and    (a.comcode like '3501%' or b.mappingcomcode like '3501%');
commit;

insert into lzm_fujian_hangbaohuanyuan_pre
  select a.policyno as ������
         ,a.endorseno as  ������
         ,a.classcode as �������
         ,a.riskcode as ���ִ���
         ,a.appliname as Ͷ��������
         ,a.insuredname as ������������
         ,a.startdate as ������
         ,a.enddate as �ձ�����
         ,a.statdate as ͳ������
         ,nvl(b.mappingcomcode,a.comcode) as ��������
         ,a.Handler1Code as ����ҵ��Ա����
         ,a.CoinsFlag as ������־
         ,a.currency as �ұ�
         ,A.cnychgSumamount * A.Coinsrate / 100 as ����
         ,A.cnychgSumpremium * A.Coinsrate / 100 as ����
  from   cgpmain A
  left join
         cgdmccommapping b
  on     a.comcode = b.comcode
  where  A.Statdate between date'2015-01-01' and date'2016-06-02'--�滻����
  and    a.classcode = 'C'
  and    (A.cnychgSumpremium * A.Coinsrate / 100 <> 0 or A.cnychgSumamount * A.Coinsrate / 100 <> 0)
  and    (a.comcode like '3501%' or b.mappingcomcode like '3501%');
commit;

--02 �˱�����
drop table lzm_fujian_hangbao_underdate;
create table lzm_fujian_hangbao_underdate
as
  select a.policyno as ������
         ,a.underwriteenddate as �˱�����
  from   cgcmain a
  where exists (select 'X' from lzm_fujian_hangbaohuanyuan_pre b where b.������ = a.policyno);

--03 ����
drop table lzm_fujian_hangbao_ShipCName;
create table lzm_fujian_hangbao_ShipCName
as
  select t.������
         ,t.����
  from
         (
         select a.policyno as ������
                ,a.ShipCName as ����
                ,row_number() over(partition by a.policyno order by a.ItemNo desc) as rn
         from   PrpCitemShip@ccicdb a
         where exists (select 'X' from lzm_fujian_hangbaohuanyuan_pre b where b.������ = a.policyno)
         )t
  where t.rn = 1;

--04 ��ȡ���
drop table lzm_fujian_hangbaohuanyuan;
create table lzm_fujian_hangbaohuanyuan
as
  select a.������
         ,a.������
         ,a.�������
         ,a.���ִ���
         ,a.Ͷ��������
         ,a.������������
         ,a.������
         ,a.�ձ�����
         ,b.�˱�����
         ,a.ͳ������
         ,a.��������
         ,a.����ҵ��Ա����
         ,a.������־
         ,a.�ұ�
         ,a.����
         ,a.����
         ,c.����
  from   lzm_fujian_hangbaohuanyuan_pre a
  left join
         lzm_fujian_hangbao_underdate b
  on     b.������ = a.������
  left join
         lzm_fujian_hangbao_ShipCName c
  on     c.������ = a.������;