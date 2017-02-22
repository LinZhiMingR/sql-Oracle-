create or replace procedure p_lp_kpi
(
 p_date IN DATE
)
---------------------------------------
--Ƶ��    ����
--Ŀ���  ��lp_kpi
---------------------------------------
IS
BEGIN
  IF p_date > DATE'2015-06-01' AND p_date = last_day(p_date) THEN
    --���Ŀ���
    delete from lp_kpi;
    commit;
--------------------------------------------------------------------------------
/* ��һ����
   ����'DDG','DDC'
   
*/
--------------------------------------------------------------------------------
    dbms_output.put_line('1 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    -- 1 δ֧������
    -- 1.1 ��������ҵ��δ֧������
    delete from lp_not_paid;
    commit;
    insert into lp_not_paid
      select distinct a.claimno
      from   prpjplanfee a
      join   prplcompensate b
      on     a.certino = b.compensateno
      and    b.underwriteflag in ('1','3')
      and    (substr(b.flag, 4, 1) <> '1' or b.flag is null)--��ҵ
      where  a.riskcode in ('DDG','DDC')
      and    substr(a.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
      and    a.claimno is not null
      group by
             a.claimno
      having sum(a.realpayreffee) - sum(a.planfee1) < 0;
    commit;
    -- 1.2 ��������ҵ��δ֧��
    insert into lp_not_paid
      select distinct b.claimno
      from   prplpayinfolist a
      join   prplcompensate b
      on     a.compensateno = b.compensateno
      join   prpjplanfee c
      on     a.payid = c.certino
      join   prplregist d
      on     b.registno = d.registno
      where  b.underwriteflag in ('1','3')
      and    b.validstatus is null
      and    b.compensatemode <> '14'
      and    b.riskcode in ('DDG','DDC')
      and    substr(d.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
      and    b.compensatetype = '2'--��ҵ
      group by b.claimno
      having sum(c.realpayreffee) - sum(c.planfee1) < 0
      union
      select a.claimno
      from   prplcompensate a
      join   prpjplanfee b
      on     a.compensateno = b.certino
      join   prplregist c
      on     a.registno = c.registno
      where  a.underwriteflag in ('1','3')
      and    a.validstatus is null
      and    a.compensatemode <> '14'
      and    a.riskcode in ('DDG','DDC')
      and    substr(c.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
      and    a.compensatetype = '2'--��ҵ
      group by a.claimno
      having sum(b.realpayreffee) - sum(b.planfee1) < 0;
    commit;
    dbms_output.put_line('1 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('2 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    
    -- 2 Ȧ��ͳ��������ҵ�հ���    
    delete from lp_claim;
    commit;
    -- 2.1 ��������ҵ��
    insert into lp_claim
      select t1.claimno
             ,t1.registno
             ,t1.claimdate
             ,t1.canceldate
             ,t1.endcasedate
             ,t2.comname2
             ,decode(substr(t1.escapeflag,3,1),'1','��','��') as �Ƿ��漰����
             ,decode(t1.autoclaimflag,'1','��','��') as �Ƿ��Զ�����
             ,t1.casetype
             ,sum(t3.sumdutypaid) as sumdutypaid
             ,'������' as Դϵͳ
      from   prplclaim t1
      join   reportnet.dimcompany t2
      on     t2.comcode = t1.comcode
      join
             prplcompensate t3
      on     t1.claimno = t3.claimno
      and    t3.underwriteflag in ('1','3')
      and    (substr(t3.flag, 4, 1) <> '1' or t3.flag is null)--��ҵ
      where  t1.riskcode in ('DDG','DDC')
      and    substr(t1.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
      and    t1.startdate between date'2015-06-01' and p_date
      and    t1.claimdate between date'2015-06-01' and p_date
      group by
             t1.claimno
             ,t1.registno
             ,t1.claimdate
             ,t1.canceldate
             ,t1.endcasedate
             ,t2.comname2
             ,decode(substr(t1.escapeflag,3,1),'1','��','��')
             ,decode(t1.autoclaimflag,'1','��','��')
             ,t1.casetype;
    commit;
    -- 2.2 �������й���û�м��������ҵ��
    insert into lp_claim
      select distinct 
             t1.claimno
             ,t1.registno
             ,t1.claimdate
             ,t1.canceldate
             ,t1.endcasedate
             ,t2.comname2
             ,decode(substr(t1.escapeflag,3,1),'1','��','��') as �Ƿ��漰����
             ,decode(t1.autoclaimflag,'1','��','��') as �Ƿ��Զ�����
             ,t1.casetype
             ,0 as sumdutypaid
             ,'������' as Դϵͳ
      from   prplclaim t1
      join   reportnet.dimcompany t2
      on     t2.comcode = t1.comcode
      join
             prplclaimloss t3
      on     t1.claimno = t3.claimno
      and    t3.kindcode <> 'BZ'--��ҵ
      where  t1.riskcode in ('DDG','DDC')
      and    substr(t1.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
      and    t1.startdate between date'2015-06-01' and p_date
      and    t1.claimdate between date'2015-06-01' and p_date
      and not exists (select 'x' from lp_claim t4 where t4.claimno = t1.claimno);
    commit;
    -- 2.3 ��������ҵ��
    insert into lp_claim
      select t1.claimno
             ,t1.registno
             ,t1.claimdate
             ,t1.canceldate
             ,t1.endcasedate
             ,t3.comname2
             ,decode(t4.involvewound,'1','��','��') as �Ƿ��漰����
             ,decode(t1.autoclaimflag,'1','��','��') as �Ƿ��Զ�����
             ,t1.casetype
             ,nvl(t1.sumdutypaid,0) as sumdutypaid
             ,'������' as Դϵͳ
      from   prplclaim t1
      left join
             prpcmain t2
      on     t2.policyno = t1.policyno
      left join
             reportnet.dimcompany t3
      on     t2.comcode = t3.comcode
      join
             prplregist t4
      on     t4.registno = t1.registno
      where  t1.riskcode in ('DDG','DDC')
      and    substr(t2.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
      and    t1.damageflag = 'BI'--��ҵ
      and    trunc(t1.claimdate) between date'2015-06-01'and p_date
      and    t2.startdate between date'2015-06-01' and p_date;
    commit;
    dbms_output.put_line('2 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('3 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 

    -- 3 ����״̬
    delete from lp_claim_casetype;
    commit;
    insert into lp_claim_casetype
      select a.claimno
             ,case when a.casetype = '0' then 'ע��'
                   when a.casetype = '1' then '����'
                   when a.endcasedate is null then 'δ�᰸'
                   when b.claimno is not null then 'δ�᰸'
                   when a.sumdutypaid = 0 then '��᰸'
                   else '�����᰸'
               end casetype
             ,a.Դϵͳ
      from   lp_claim a
      left join
             lp_not_paid b
      on     a.claimno = b.claimno;
    commit;
    
    dbms_output.put_line('3 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('4 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 4 �ʽ�֧��ʱ��
    -- 4.1 ȡ���κ�
    delete from lp_zj_pre;
    commit;
    insert into lp_zj_pre
      -- ������
      select a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
      join   prpjplanfee c
      on     c.certino = b.compensateno
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������'
      union
      select /*+parallel(c 8)*/a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
      join   prpjplanfeehis c
      on     c.certino = b.compensateno
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������'
      -- ������Ԥ��
      union
      select a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
      join   prpjplanfee c
      on     c.certino = b.precompensateno
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������'
      union
      select /*+parallel(c 8)*/a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
      join   prpjplanfeehis c
      on     c.certino = b.precompensateno
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������'
      -- ������
      union
      select a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    b.validstatus is null
      and    b.compensatemode <> '14'
      join   prplpayinfolist c
      on     b.compensateno = c.compensateno
      join   prpjplanfee d
      on     d.certino = c.payid
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������'
      union
      select /*+parallel(d 8)*/a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    b.validstatus is null
      and    b.compensatemode <> '14'
      join   prplpayinfolist c
      on     b.compensateno = c.compensateno
      join   prpjplanfeehis d
      on     d.certino = c.payid
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������'
      -- ������Ԥ��
      union
      select a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      join   prplpayinfolist c
      on     b.precompensateno = c.compensateno
      join   prpjplanfee d
      on     d.certino = c.payid
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������'
      union
      select /*+parallel(d 8)*/a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_casetype a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      join   prplpayinfolist c
      on     b.precompensateno = c.compensateno
      join   prpjplanfeehis d
      on     d.certino = c.payid
      where  a.casetype = '�����᰸'
      and    a.Դϵͳ = '������';
    commit;
    
    -- 4.2 ȡ���κŵ�һ�η���ʱ������ֵ
    delete from lp_zj;
    commit;
    insert into lp_zj
      select claimno,max(d_paysentdate) as d_paysentdate
      from
             (
              select /*+parallel(b 8)*/
                     a.claimno
                     ,b.c_memo
                     ,b.d_paysentdate
                     ,row_number() over(partition by a.claimno,b.c_memo order by b.d_paysentdate) as rn
              from   lp_zj_pre a
              join   reportnet.tse_payments b
              on     a.paybatchno = b.c_memo
              where  b.c_paystate in ('2','3','4')
             )
      where  rn = 1
      group by claimno;
    commit;
      
    dbms_output.put_line('4 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('5 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 5 �ո���ϵͳ֧��ʱ��
    delete from lp_realpaydate;
    commit;
    insert into lp_realpaydate
      select claimno,max(Realpaydate) as Realpaydate
      from
             (
              --������
              select a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
              join   prpjrefrec c
              on     c.certino = b.compensateno
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    c.realpaydate is not null
              union
              select a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
              join   prpjrefrechis c
              on     c.certino = b.compensateno
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    c.realpaydate is not null
              --������Ԥ��
              union
              select a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
              join   prpjrefrec c
              on     c.certino = b.precompensateno
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    c.realpaydate is not null
              union
              select a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
              join   prpjrefrechis c
              on     c.certino = b.precompensateno
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    c.realpaydate is not null
              --������
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    b.validstatus is null
              and    b.compensatemode <> '14'
              join   prplpayinfolist c
              on     b.compensateno = c.compensateno
              join   prpjrefrec d
              on     d.certino = c.payid
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    d.realpaydate is not null
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    b.validstatus is null
              and    b.compensatemode <> '14'
              join   prplpayinfolist c
              on     b.compensateno = c.compensateno
              join   prpjrefrechis d
              on     d.certino = c.payid
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    d.realpaydate is not null
              --������Ԥ��
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              join   prplpayinfolist c
              on     b.precompensateno = c.compensateno
              join   prpjrefrec d
              on     d.certino = c.payid
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    d.realpaydate is not null
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_casetype a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              join   prplpayinfolist c
              on     b.precompensateno = c.compensateno
              join   prpjrefrechis d
              on     d.certino = c.payid
              where  a.casetype = '�����᰸'
              and    a.Դϵͳ = '������'
              and    d.realpaydate is not null
             )
      group by claimno;
    commit;

    dbms_output.put_line('5 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('6 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 6 ������
    delete from lp_sumloss;
    commit;
    insert into lp_sumloss
      select a.claimno
             ,sum(b.sumclaim) as sumclaim
      from   lp_claim_casetype a
      join   prplclaimloss b
      on     a.claimno = b.claimno
      and    (b.kindcode <> 'BZ' or b.kindcode is null)
      where  a.Դϵͳ = '������'
      group by a.claimno
      union
      select a.claimno
             ,sum(b.sumclaim) as sumclaim
      from   lp_claim_casetype a
      join   prplclaimloss b
      on     a.claimno = b.claimno
      where  a.Դϵͳ = '������'
      group by a.claimno;
    commit;

    dbms_output.put_line('6 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('7 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 7 �������ʱ��
    delete from lp_hepei;
    commit;
    insert into lp_hepei
      select claimno,max(underwriteenddate) as underwriteenddate
      from
             (
              select a.claimno,to_date(c.submittime,'yyyy-mm-dd hh24:mi:ss') as underwriteenddate
              from   lp_claim_casetype a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
              join   Swflogstore c
              on     b.compensateno = c.businessno
              and    c.nodestatus = '4'
              where  a.Դϵͳ = '������'
              and    a.casetype = '�����᰸'
              union
              select a.claimno,to_date(c.submittime,'yyyy-mm-dd hh24:mi:ss') as underwriteenddate
              from   lp_claim_casetype a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
              join   Swflog c
              on     b.compensateno = c.businessno
              and    c.nodestatus = '4'
              where  a.Դϵͳ = '������'
              and    a.casetype = '�����᰸'
              union
              select a.claimno,b.underwriteenddate
              from   lp_claim_casetype a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    b.validstatus is null
              and    b.compensatemode <> '14'
              and    (b.compensatemode <> '7' or b.compensatemode is null)
              where  a.Դϵͳ = '������'
              and    a.casetype = '�����᰸'
             )
      group by claimno;
    commit;

    dbms_output.put_line('7 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('8 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 8 �ϲ�
    delete from lp_claim_main;
    commit;
    insert into lp_claim_main
      select a.claimno
             ,a.registno
             ,a.claimdate
             ,a.canceldate
             ,a.endcasedate
             ,a.comname2
             ,a.�Ƿ��漰����
             ,a.�Ƿ��Զ�����
             ,a.sumdutypaid
             ,b.casetype
             ,nvl(c.d_paysentdate,d.realpaydate) as realpaydate
             ,e.underwriteenddate
             ,f.sumclaim
             ,a.Դϵͳ
      from lp_claim a
      join lp_claim_casetype b
      on   a.claimno = b.claimno
      left join
           lp_zj c
      on   a.claimno = c.claimno
      left join
           lp_realpaydate d
      on   a.claimno = d.claimno
      left join
           lp_hepei e
      on   e.claimno = a.claimno
      left join
           lp_sumloss f
      on   a.claimno = f.claimno;
    commit;
    dbms_output.put_line('8 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    --------------------------------------------------------------------------------------
    --(1) ���ⰸ����������
    insert into lp_kpi
      select 1
             ,'���ⰸ����������'
             ,t.comname2
             ,null
             ,null
             ,count(*)
      from   lp_claim_main t
      where  trunc(t.claimdate) between trunc(p_date,'yyyy') and p_date
      group by t.comname2;
    commit;
    --(2) ��ҵ�����漰���˰�����������
    insert into lp_kpi
      select 2
             ,'��ҵ�����漰���˰�����������'
             ,t.comname2
             ,null
             ,null
             ,count(*)
      from   lp_claim_main t
      where  t.�Ƿ��漰���� = '��'
      and    trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
      group by t.comname2;
      if sql%rowcount = 0
           then insert into lp_kpi values(2,'��ҵ�����漰���˰�����������',null,null,null,0);
      end if;
    commit;
    --(3) ��ҵ�������˰�����Ԫ��
    insert into lp_kpi
      select 3
             ,'��ҵ�������˰�����Ԫ��'
             ,t.comname2
             ,null
             ,null
             ,sum(t.sumdutypaid)
      from   lp_claim_main t
      where  t.�Ƿ��漰���� = '��'
      and    trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
      group by t.comname2;
      if sql%rowcount = 0
           then insert into lp_kpi values(3,'��ҵ�������˰�����Ԫ��',null,null,null,0);
      end if;
    commit;
---------------------------------------------------------------------------------------------
    dbms_output.put_line('9 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 9 ������Ϣ
    delete from lp_regist;
    commit;
    -- 9.1 �����ⱨ����Ϣ
    insert into lp_regist
    select t1.registno            as ������
           ,t2.comname2           as comname2
           ,trunc(t1.canceldate)  as ע������
           ,to_date(to_char(t1.reportdate, 'yyyy-mm-dd') || ' ' || t1.reporthour, 'yyyy-mm-dd hh24:mi:ss') as ��������
           ,'������'
    from   prplregist t1
    join   reportnet.dimcompany t2
    on     t2.comcode = t1.comcode
    join   prpcmain t3
    on     t3.policyno = t1.policyno
    and    t3.startdate between date'2015-06-01' and p_date
    where  t1.reportdate between date'2015-06-01' and p_date
    and    t1.riskcode in ('DDG','DDC')
    and    substr(t1.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
    and    (replace(replace(replace(replace(t1.damagekind,'A:',null),'U:',null),'BZ',null),',',null) is not null
           or t1.damagekind is null);
    commit;
    -- 9.2 �����ⱨ����Ϣ
    insert into lp_regist
    select t1.registno            as ������
           ,t2.comname2           as comname2
           ,trunc(t1.canceldate)  as ע������
           ,to_date(to_char(t1.reportdate, 'yyyy-mm-dd') || ' ' || t1.reporthour, 'yyyy-mm-dd hh24:mi:ss') as ��������
           ,'������'              as Դϵͳ
    from   prplregist t1
    join   reportnet.dimcompany t2
    on     t2.comcode = t1.comcode
    join   prpcmain t3
    on     t3.policyno = t1.policyno
    and    t3.startdate between date'2015-06-01' and p_date
    where  t1.reportdate between date'2015-06-01' and p_date
    and    t1.riskcode in ('DDG','DDC')
    and    substr(t1.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
    and exists (select /*+parallel(t 8)*/ 1 from prplimplicateitemkind t where t.registno = t1.registno and t.kindcode <> 'BZ');
    commit;
    
    dbms_output.put_line('9 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('10 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    
    -- 10 �����᰸�ĵ�֤�ռ�����
    -- 10.1 ������
    delete from lp_certifycollect;
    commit;
    insert into lp_certifycollect
    select t1.registno
           ,to_date(max(t2.allcollecttime), 'yyyy-mm-dd hh24:mi:ss') as allcollecttime
    from   lp_claim_main t1
    join   prplcertifycollect t2
    on     t1.registno = t2.businessno
    where  t2.allcollecttime is not null
    and    t1.casetype = '�����᰸'
    and    t1.Դϵͳ = '������'
    group by t1.registno;
    commit;
    -- 10.2 ������
    insert into lp_certifycollect
    select t.registno,max(endtime) as allcollecttime
    from
            (
            select t1.registno
                   ,t2.endtime
            from   lp_claim_main t1
            join   t_edf_task t2
            on     t1.registno = t2.registno
            and    t2.tasktype  ='DocCollect'
            where  t1.casetype = '�����᰸'
            and    t1.Դϵͳ = '������'
            and    t2.endtime is not null
            union all
            select t1.registno
                   ,t2.endtime
            from   lp_claim_main t1
            join   t_edf_taskhis t2
            on     t1.registno = t2.registno
            and    t2.tasktype  ='DocCollect'
            where  t1.casetype = '�����᰸'
            and    t1.Դϵͳ = '������'
            and    t2.endtime is not null
            )t
    group by t.registno;
    commit;
    
    insert into lp_certifycollect
    select t.registno,min(createtime) as allcollecttime
    from   (
            select t1.registno
                   ,t2.createtime
            from   lp_claim_main t1
            join   t_edf_task t2
            on     t1.registno = t2.registno
            and    t2.tasktype  ='Compensate'
            where  t1.casetype = '�����᰸'
            and    t1.Դϵͳ = '������'
            and not exists (select 1 from lp_certifycollect tt where tt.registno = t1.registno)
            union all
            select t1.registno
                   ,t2.createtime
            from   lp_claim_main t1
            join   t_edf_taskhis t2
            on     t1.registno = t2.registno
            and    t2.tasktype  ='Compensate'
            where  t1.casetype = '�����᰸'
            and    t1.Դϵͳ = '������'
            and not exists (select 1 from lp_certifycollect tt where tt.registno = t1.registno)
           )t
    group by t.registno;
    dbms_output.put_line('10 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
---------------------------------------------------------------------------------------------------------
    --(4) ��������֧������
    insert into lp_kpi
    select 4
           ,'��������֧������'
           ,t1.comname2
           ,sum(t1.realpaydate-t2.��������)
           ,count(*)
           ,round(sum(t1.realpaydate-t2.��������)/count(*),2)
    from   lp_claim_main t1
    join   lp_regist t2  --��������
    on     t2.������ = t1.registno
    where  trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    group by t1.comname2;
    commit;
    --(5) ����������������
    insert into lp_kpi
    select 5
           ,'����������������'
           ,t1.comname2
           ,sum(t2.allcollecttime-t3.��������)
           ,count(*)
           ,round(sum(t2.allcollecttime-t3.��������)/count(*),2)
    from   lp_claim_main t1
    join   lp_certifycollect t2 --��֤�ռ�����
    on     t2.registno = t1.registno
    join   lp_regist t3         --��������
    on     t3.������ = t1.registno
    where  trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    group by t1.comname2;
    commit;
    --(6) ���������������
    insert into lp_kpi
    select 6
           ,'���������������'
           ,t1.comname2
           ,sum(t1.underwriteenddate-t2.allcollecttime)
           ,count(*)
           ,round(sum(t1.underwriteenddate-t2.allcollecttime)/count(*),2)
    from   lp_claim_main t1
    join   lp_certifycollect t2 --��֤�ռ�����
    on     t2.registno = t1.registno
    where  trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    group by t1.comname2;
    commit;
    --(7) ��������֧������
    insert into lp_kpi
    select 7
           ,'��������֧������'
           ,t1.comname2
           ,sum(t1.realpaydate-t1.underwriteenddate)
           ,count(*)
           ,round(sum(t1.realpaydate-t1.underwriteenddate)/count(*),2)
    from   lp_claim_main t1
    where  trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    group by t1.comname2;
    commit;
    --(8) �����᰸�ʣ����ڣ�
    insert into lp_kpi
    select 8
           ,'�����᰸�ʣ����ڣ�'
           ,t.comname2
           ,sum(case when t.casetype in ('ע��','����','��᰸')
                     and  trunc(t.endcasedate) between trunc(p_date,'yyyy') and p_date
                     then 1
                     when t.casetype = '�����᰸'
                     and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                     then 1
                     else 0 
                end)
           ,count(*)
           ,round(sum(case when t.casetype in ('ע��','����','��᰸')
                           and  trunc(t.endcasedate) between trunc(p_date,'yyyy') and p_date
                           then 1
                           when t.casetype = '�����᰸'
                           and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                           then 1
                           else 0 
                      end)
                  /count(*),2)
    from   lp_claim_main t
    where  trunc(t.claimdate) between trunc(p_date,'yyyy') and p_date
    group by t.comname2;
    commit;
    --(9) �����᰸�ʣ�������
    insert into lp_kpi
    select 9
           ,'�����᰸�ʣ�������'
           ,t.comname2
           ,sum(case when t.casetype in ('ע��','����','��᰸')
                     and  trunc(t.endcasedate) between trunc(p_date,'yyyy') and p_date
                     then 1
                     when t.casetype = '�����᰸'
                     and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                     then 1
                     else 0
                end)
           ,case when t.comname2 = '�����ֹ�˾' then 308
                 when t.comname2 = '�������ֹ�˾' then 195
                 when t.comname2 = '�ൺ�ֹ�˾' then 302
                 when t.comname2 = 'ɽ���ֹ�˾' then 1529
                 when t.comname2 = '�����ֹ�˾' then 778
                 when t.comname2 = '����ֹ�˾' then 233
            end
           ,round(sum(case when t.casetype in ('ע��','����','��᰸')
                           and  trunc(t.endcasedate) between trunc(p_date,'yyyy') and p_date
                           then 1
                           when t.casetype = '�����᰸'
                           and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                           then 1
                           else 0
                      end)
                  /case when t.comname2 = '�����ֹ�˾' then 308
                        when t.comname2 = '�������ֹ�˾' then 195
                        when t.comname2 = '�ൺ�ֹ�˾' then 302
                        when t.comname2 = 'ɽ���ֹ�˾' then 1529
                        when t.comname2 = '�����ֹ�˾' then 778
                        when t.comname2 = '����ֹ�˾' then 233
                   end
                  ,2)  
    from   lp_claim_main t
    where  trunc(t.claimdate) < trunc(p_date,'yyyy')
    group by t.comname2;
    commit;
    --(10) ���᰸��
    insert into lp_kpi
    select 10
           ,'���᰸��'
           ,t.comname2
           ,sum(case when t.casetype = '�����᰸'
                     and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                     then t.sumdutypaid
                     else 0
                end)
           ,sum(case when t.casetype = '�����᰸'
                     and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                     then t.sumdutypaid
                     else 0
                end)
            +sum(case when t.casetype = '�����᰸'
                      and  trunc(t.realpaydate) > p_date --��ĩ֮��᰸����������
                      then t.sumclaim
                      when t.casetype in ('ע��','����','��᰸')
                      and  trunc(t.endcasedate) > p_date --��ĩ֮��᰸�����ⰸ��
                      then t.sumclaim
                      when t.casetype = 'δ�᰸' 
                      then t.sumclaim
                      else 0
                 end)
           ,round(sum(case when t.casetype = '�����᰸'
                           and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                           then t.sumdutypaid
                           else 0
                      end)
                  /(
                    sum(case when t.casetype = '�����᰸'
                             and  trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
                             then t.sumdutypaid
                             else 0
                        end)
                    +sum(case when t.casetype = '�����᰸'
                              and  trunc(t.realpaydate) > p_date --��ĩ֮��᰸����������
                              then t.sumclaim
                              when t.casetype in ('ע��','����','��᰸')
                              and  trunc(t.endcasedate) > p_date --��ĩ֮��᰸�����ⰸ��
                              then t.sumclaim
                              when t.casetype = 'δ�᰸' 
                              then t.sumclaim
                              else 0
                         end)
                    ),2)
    from   lp_claim_main t
    where  trunc(t.claimdate) between trunc(p_date,'yyyy') and p_date
    group by t.comname2;
    commit;
    --(11) ����������
    insert into lp_kpi
    select 11
           ,'����������'
           ,t1.company
           ,t1.c_values
           ,nvl(t2.��Ч������,0)
           ,round(t1.c_values/nvl(t2.��Ч������,0),2)
    from   lp_kpi t1
    left join
           (
            select t.����
                   ,count(t.������) as ��Ч������
            from   lp_regist t
            where  trunc(t.��������) between trunc(p_date,'yyyy') and p_date
            and    (t.ע������ is null or t.ע������ > p_date)
            group by t.����
           )t2
    on     t2.���� = t1.company
    where  t1.id_no = 1;
    commit;
    --(12) ϵͳǿ��������
    insert into lp_kpi
    select 12
           ,'ϵͳǿ��������'
           ,t.comname2
           ,sum(case when t.�Ƿ��Զ����� = '��' then 1 else 0 end)
           ,count(*)
           ,round(sum(case when t.�Ƿ��Զ����� = '��' then 1 else 0 end)/count(*),2)
    from   lp_claim_main t
    where  trunc(t.claimdate) between trunc(p_date,'yyyy') and p_date
    group by t.comname2;
    commit;
----------------------------------------------------------------------------------------------
    dbms_output.put_line('11 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 11 �ؿ�����
    -- 11.1 �������ؿ���
    delete from lp_recase;
    commit;
    insert into lp_recase
    select t1.claimno
           ,t3.comname2
           ,t1.closecasedate
           ,t1.recancelflag
           ,'������'
    from   prplrecase t1
    join   prplclaim t2
    on     t2.claimno = t1.claimno
    join   reportnet.dimcompany t3
    on     t2.comcode = t3.comcode
    where  trunc(t1.opencasedate) between trunc(p_date,'yyyy') and p_date
    and    t2.startdate between date'2015-06-01' and p_date
    and    t2.riskcode in ('DDG','DDC')
    and    substr(t2.comcode,1,4) in ('2301','3701','4501','5001','6101','3702');
    commit;
    insert into lp_recase
    select /*+parallel(t1 8)*/
           t1.claimno
           ,t3.comname2
           ,t1.closeendcasedate --�ؿ���᰸ʱ��
           ,t1.recancelflag
           ,'������'
    from   prplvirtualclaim t1
    join   prplclaim t2
    on     t2.claimno = t1.claimno
    join   reportnet.dimcompany t3
    on     t2.comcode = t3.comcode
    where  trunc(t1.claimcanceldate) between trunc(p_date,'yyyy') and p_date
    and    t2.startdate between date'2015-06-01' and p_date
    and    t2.riskcode in ('DDG','DDC')
    and    substr(t2.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
    and    t1.validstatus in ('8','7');
    commit;
    -- 11.2 �������ؿ���
    insert into lp_recase
    select t1.claimno                         as ������
           ,t3.comname2                       as ����
           ,t1.endcasedate                    as �ؿ���᰸ʱ��
           ,t1.recancelflag||t1.opencasetimes as ע������ָ���ʾ
           ,'������'                          as Դϵͳ
    from   prplrecase t1
    join   prpcmain t2
    on     t2.policyno = t1.policyno
    join   reportnet.dimcompany t3
    on     t2.comcode = t3.comcode
    where  trunc(t1.opencasedate) between trunc(p_date,'yyyy') and p_date
    and    t2.startdate between date'2015-06-01' and p_date
    and    t2.riskcode in ('DDG','DDC')
    and    t1.opencasetype in ('02','03')
    and    substr(t2.comcode,1,4) in ('2301','3701','4501','5001','6101','3702')
    and    t1.flag = '1';
    commit;

    dbms_output.put_line('11 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    dbms_output.put_line('12 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 12 �ؿ������Ѿ����
    -- 12.1 ������
    delete from lp_recase_compensate;
    commit;
    insert into lp_recase_compensate
    select t1.������
           ,t1.����
           ,sum(t2.sumpaid) as �ؿ����Ѿ����
    from   lp_recase t1
    join   prplcompensate t2
    on     t2.claimno = t1.������
    and    t2.recancelflag = t1.ע������ָ���ʾ
    and    t2.underwriteflag in ('1','3')
    and    (substr(t2.flag,4,1) <> '1' or t2.flag is null)
    where  trunc(t1.�ؿ���᰸ʱ��) between trunc(p_date,'yyyy') and p_date
    and    t1.Դϵͳ = '������'
    group by
           t1.������
           ,t1.����;
    commit;
    -- 12.2 ������
    insert into lp_recase_compensate
    select t1.������
           ,t1.����
           ,sum(t2.sumpaid) as �ؿ����Ѿ����
    from   lp_recase t1
    join   prplcompensate t2
    on     t2.claimno = t1.������
    and    t2.validstatus is null
    and    t2.compensatemode <> '14'
    and    t2.recancelflag||t2.recaseno = t1.ע������ָ���ʾ
    and    t2.underwriteflag in ('1','3')
    and    t2.compensatetype = '2'--��ҵ
    where  trunc(t1.�ؿ���᰸ʱ��) between trunc(p_date,'yyyy') and p_date
    and    t1.Դϵͳ = '������'
    group by
           t1.������
           ,t1.����;
    commit;
    dbms_output.put_line('12 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
----------------------------------------------------------------------------------------------------------------
    --(13) �ⰸ�ؿ��ʣ�������
    insert into lp_kpi
    select 13
           ,'�ⰸ�ؿ��ʣ�������'
           ,t1.company
           ,nvl(t2.�ؿ��ⰸ��,0)
           ,t1.c_values
           ,round(nvl(t2.�ؿ��ⰸ��,0)/t1.c_values,2)
    from   lp_kpi t1
    left join
           (
           select t.����
                  ,count(distinct t.������) as �ؿ��ⰸ��
           from   lp_recase t
           group by t.����
           )t2
    on     t2.���� = t1.company
    where  t1.id_no = 1;
    commit;
    --(14) �ⰸ�ؿ��ʣ���
    insert into lp_kpi
    select 14
           ,'�ⰸ�ؿ��ʣ���'
           ,t1.company
           ,nvl(t2.�ؿ����Ѿ����,0)
           ,t1.fenmu
           ,round(nvl(t2.�ؿ����Ѿ����,0)/t1.fenmu,2)
    from   lp_kpi t1
    left join
           (
           select t.����
                  ,sum(t.�ؿ����Ѿ����) as �ؿ����Ѿ����
           from   lp_recase_compensate t
           group by t.����
           )t2
    on     t2.���� = t1.company
    where  t1.id_no = 10;
    commit;
--------------------------------------------------------------------------
    dbms_output.put_line('13 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 13 �������δ��������
    -- 13.1 ������
    delete from lp_piancha;
    commit;
    insert into lp_piancha
    select t1.claimno
           ,t1.comname2
           ,t1.sumdutypaid
           ,sum(nvl(t3.sumclaim,0)) ����δ��������
    from   lp_claim_main t1
    join   prplclaim t2
    on     t2.claimno = t1.claimno
    left join
           prplclaimloss t3
    on     t3.claimno = t1.claimno
    and    t2.claimdate = t3.inputdate
    and    t3.kindcode <> 'BZ'
    and    t3.flag <> '9916'
    where  t1.Դϵͳ = '������'
    and    t1.casetype = '�����᰸'
    and    trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    group by
           t1.claimno
           ,t1.comname2
           ,t1.sumdutypaid;
    commit;
    -- 13.2 ������
    insert into lp_piancha
    select t1.claimno
           ,t1.comname2
           ,t1.sumdutypaid
           ,sum(nvl(t3.sumclaim,0)) ����δ��������
    from   lp_claim_main t1
    join   prplclaim t2
    on     t2.claimno = t1.claimno
    left join
           prplclaimloss t3
    on     t3.claimno = t1.claimno
    and    trunc(t2.claimdate) = t3.inputtime
    where  t1.Դϵͳ = '������'
    and    t1.casetype = '�����᰸'
    and    trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    group by
           t1.claimno
           ,t1.comname2
           ,t1.sumdutypaid;
    commit;
    dbms_output.put_line('13 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
    
    --(15) ���ι������ƫ����
    insert into lp_kpi
    select 15
           ,'���ι������ƫ����'
           ,t.����
           ,sum(t.����δ��������-t.�Ѿ����)
           ,sum(t.�Ѿ����)
           ,round(sum(t.����δ��������-t.�Ѿ����)/sum(t.�Ѿ����),2)
    from   lp_piancha t
    group by t.����;
    commit;
    --(16) ���ι������ƫ����
    insert into lp_kpi
    select 16
           ,'���ι������ƫ����'
           ,t.����
           ,sum(abs(t.����δ��������-t.�Ѿ����))
           ,sum(t.�Ѿ����)
           ,round(sum(abs(t.����δ��������-t.�Ѿ����))/sum(t.�Ѿ����),2)
    from   lp_piancha t
    group by t.����;
    commit;
    --(17) ���⸶�᰸��
    insert into lp_kpi
    select 17
           ,'���⸶�᰸��'
           ,t.comname2
           ,sum(decode(t.casetype,'��᰸',1,0))
           ,count(*)
           ,round(sum(decode(t.casetype,'��᰸',1,0))
                  /decode(count(*),0,null,count(*))
                  ,2)
    from   lp_claim_main t
    where  (t.casetype = '�����᰸' and trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date)
    or     (t.casetype in ('ע��','����','��᰸') and trunc(t.endcasedate) between trunc(p_date,'yyyy') and p_date)
    group by t.comname2;
    commit;
    --(18) ����ע����
    insert into lp_kpi
    select 18
           ,'����ע����'
           ,t.����
           ,sum(case when trunc(t.ע������) between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
           ,sum(case when trunc(t.��������) between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
           ,round(sum(case when t.ע������ between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
                  /sum(case when trunc(t.��������) between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
                  ,2)
    from   lp_regist t
    group by t.����;
    commit;
    --(19) ����ע���ʣ�������
    insert into lp_kpi
    select 19
           ,'����ע���ʣ�������'
           ,t.comname2
           ,sum(case when trunc(t.canceldate) between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
           ,sum(case when trunc(t.claimdate) between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
           ,round(sum(case when trunc(t.canceldate) between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
                  /sum(case when trunc(t.claimdate) between trunc(p_date,'yyyy') and p_date then 1 else 0 end)
                  ,2)
    from   lp_claim_main t
    group by t.comname2;
    commit;
    --(20) ����ע���ʣ���
    insert into lp_kpi
    select 20
           ,'����ע���ʣ���'
           ,t1.company
           ,nvl(t2.sumclaim,0)
           ,t1.fenmu
           ,round(nvl(t2.sumclaim,0)/t1.fenmu,2)
    from   lp_kpi t1
    left join
           (
           select t.comname2
                  ,sum(t.sumclaim) as sumclaim
           from   lp_claim_main t
           where  trunc(t.canceldate) between trunc(p_date,'yyyy') and p_date
           group by t.comname2
           )t2
    on     t2.comname2 = t1.company
    where  t1.id_no = 10;
    commit;
    --(21) �����Ѿ����
    insert into lp_kpi
    select 21
           ,'�����Ѿ����'
           ,t.comname2
           ,sum(t.sumdutypaid)
           ,count(*)
           ,round(sum(t.sumdutypaid)/count(*),2)
    from   lp_claim_main t
    where  t.casetype = '�����᰸'
    and    trunc(t.realpaydate) between trunc(p_date,'yyyy') and p_date
    group by t.comname2;
    commit;
    --(22) ����δ�����
    insert into lp_kpi
    select 22
           ,'����δ�����'
           ,t.comname2
           ,sum(t.sumclaim)
           ,count(*)
           ,round(sum(t.sumclaim)/count(*),2)
    from   lp_claim_main t
    where  t.casetype = 'δ�᰸'
    or     (t.casetype = '�����᰸' and trunc(t.realpaydate) > p_date)
    or     (t.casetype in ('ע��','����','��᰸') and trunc(t.endcasedate) > p_date)
    group by t.comname2;
    commit;
--------------------------------------------------------------------------------------------------
    dbms_output.put_line('14 start:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')); 
    -- 14 ֱ���������
    -- 14.1 ������
    delete from lp_charge;
    commit;
    insert into lp_charge
    select t1.claimno
           ,t1.comname2
           ,sum(t3.chargeamount) as ֱ���������
    from   lp_claim_main t1
    join   prplcompensate t2
    on     t2.claimno = t1.claimno
    and    t2.underwriteflag in ('1','3')
    and    (substr(t2.flag,4,1) <> '1' or t2.flag is null)
    join   prplcharge t3
    on     t2.compensateno = t3.compensateno
    and    t3.chargecode <> '9916'
    where  t1.casetype in ('ע��','����','��᰸')
    and    trunc(t1.endcasedate) between trunc(p_date,'yyyy') and p_date
    and    t1.Դϵͳ = '������'
    group by
           t1.claimno
           ,t1.comname2
    union
    select t1.claimno
           ,t1.comname2
           ,sum(t3.chargeamount) as ֱ���������
    from   lp_claim_main t1
    join   prplcompensate t2
    on     t2.claimno = t1.claimno
    and    t2.underwriteflag in ('1','3')
    and    (substr(t2.flag,4,1) <> '1' or t2.flag is null)
    join   prplcharge t3
    on     t2.compensateno = t3.compensateno
    and    t3.chargecode <> '9916'
    where  t1.casetype = '�����᰸'
    and    trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    and    t1.Դϵͳ = '������'
    group by
           t1.claimno
           ,t1.comname2;
    commit;
    
    -- 14.2 ������
    insert into lp_charge
    select t1.claimno
           ,t1.comname2
           ,sum(t3.chargeamount) as ֱ���������
    from   lp_claim_main t1
    join   prplcompensate t2
    on     t2.claimno = t1.claimno
    and    t2.underwriteflag in ('1','3')
    and    t2.validstatus is null
    and    t2.compensatemode <> '14'
    join   prplcharge t3
    on     t2.compensateno = t3.compensateno
    and    t3.chargecode <> '9916'
    where  t1.casetype in ('ע��','����','��᰸')
    and    trunc(t1.endcasedate) between trunc(p_date,'yyyy') and p_date
    and    t1.Դϵͳ = '������'
    group by
           t1.claimno
           ,t1.comname2
    union
    select t1.claimno
           ,t1.comname2
           ,sum(t3.chargeamount) as ֱ���������
    from   lp_claim_main t1
    join   prplcompensate t2
    on     t2.claimno = t1.claimno
    and    t2.underwriteflag in ('1','3')
    and    t2.validstatus is null
    and    t2.compensatemode <> '14'
    join   prplcharge t3
    on     t2.compensateno = t3.compensateno
    and    t3.chargecode <> '9916'
    where  t1.casetype = '�����᰸'
    and    trunc(t1.realpaydate) between trunc(p_date,'yyyy') and p_date
    and    t1.Դϵͳ = '������'
    group by
           t1.claimno
           ,t1.comname2;
    commit;
    dbms_output.put_line('14 end:'||to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'));
-------------------------------------------------------------
    --(23) �Ѿ�����ֱ���������
    insert into lp_kpi
    select 23
           ,'�Ѿ�����ֱ���������'
           ,t1.����
           ,sum(t1.ֱ���������)
           ,count(t1.������)
           ,round(sum(t1.ֱ���������)/count(t1.������),2)
    from   lp_charge t1
    group by t1.����;
    commit;

--------------------------------------------------------------
/***************   �ڶ����֣� ȫ������ ***************/
--------------------------------------------------------------
    --1�����ⰸ����������
    insert into lp_kpi
    select 1
           ,'���ⰸ����������'
           ,'ȫ��'
           ,NULL
           ,NULL
           ,count(*)
    from
           (
            select distinct t1.claimno
            from   prplclaim t1
            join   prplclaimloss t2
            on     t2.claimno = t1.claimno
            and    t2.kindcode <> 'BZ'
            where  t1.classcode = 'D'
            and    t1.claimdate between trunc(p_date,'yyyy') and p_date
            union
            select t1.claimno
            from   prplclaim t1
            where  t1.classcode = 'D'
            and    t1.damageflag = 'BI'
            and    trunc(t1.claimdate) between trunc(p_date,'yyyy') and p_date
           );
     commit;
---------------------------------------------------------------------------------------
    --δ֧������
    --��������ҵ��δ֧������
    delete from lp_not_paid_car;
    commit;
    insert into lp_not_paid_car
      select /*+parallel(t 8)*/
             distinct a.claimno
      from   prpjplanfee a
      join   prplcompensate b
      on     a.certino = b.compensateno
      and    b.underwriteflag in ('1','3')
      and    (substr(b.flag, 4, 1) <> '1' or b.flag is null)--��ҵ
      where  a.classcode = 'D'
      and    a.claimno is not null
      GROUP BY
             a.Claimno
      having sum(a.RealPayRefFee) - sum(a.planfee1) < 0;
    commit;
    --��������ҵ��δ֧��
    insert into lp_not_paid_car
      select distinct b.Claimno
      from   prplpayinfolist a
      join   prplcompensate b
      on     a.compensateno = b.compensateno
      and    b.underwriteflag in ('1','3')
      and    b.validstatus is null
      and    b.compensatemode <> '14'
      join   prpjplanfee c
      on     a.payid = c.Certino
      join   prplregist d
      on     b.registno = d.registno
      where  b.underwriteflag in ('1','3')
      and    b.classcode = 'D'
      and    b.compensatetype = '2'--��ҵ
      group by b.Claimno
      having sum(c.RealPayRefFee) - sum(c.planfee1) < 0
      union
      select a.Claimno
      from   prplcompensate a
      join   prpjplanfee b
      on     a.compensateno = b.certino
      join   prplregist c
      on     a.registno = c.registno
      where  a.underwriteflag in ('1','3')
      and    a.validstatus is null
      and    a.compensatemode <> '14'
      and    a.classcode = 'D'
      and    a.compensatetype = '2'--��ҵ
      group by a.Claimno
      having sum(b.RealPayRefFee) - sum(b.planfee1) < 0;
    commit;
    
    
    --Ȧ��2015-06-01���Ѿ���ҵ�հ���
    delete from lp_claim_renshang;
    commit;
    ----- ��������ҵ��
    insert into lp_claim_renshang
      select /*+full(t2) parallel(t2 8)*/
             t1.claimno
             ,sum(t2.sumdutypaid) as sumdutypaid
             ,'������' as Դϵͳ
      from   prplclaim t1
      join
             prplcompensate t2
      on     t1.claimno = t2.claimno
      and    t2.underwriteflag in ('1','3')
      and    (substr(t2.flag, 4, 1) <> '1' or t2.flag is null)--��ҵ
      where  t1.classcode = 'D'
      and    substr(t1.escapeflag,3,1) = '1' --�漰����
      and    (t1.casetype not in ('0','1') or t1.casetype is null)--�޳�ע������
      and    t1.endcasedate is not null --�ѽ᰸
      and not exists (select 'x' from lp_not_paid_car t where t.claimno = t1.claimno)--��֧��
      group by
             t1.claimno;
    commit;
    -----��������ҵ��
    insert into lp_claim_renshang
      select t1.claimno
             ,nvl(t1.sumdutypaid,0) as sumdutypaid
             ,'������' as Դϵͳ
      from   prplclaim t1
      join
             prplregist t3
      on     t3.registno = t1.registno
      where  t1.classcode = 'D'
      and    t1.damageflag = 'BI'--��ҵ
      and    t1.endcasedate is not null --�ѽ᰸
      and    (t1.casetype not in ('0','1') or t1.casetype is null)--�޳�ע������
      and    t3.involvewound = '1' --�漰����
      and not exists (select 'x' from lp_not_paid_car t where t.claimno = t1.claimno)--��֧��
      ;
    commit;


    -- 9 �ʽ�֧��ʱ��
    delete from lp_car_zj_pre;
    commit;
    insert into lp_car_zj_pre
      --������
      select a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
      join   prpjplanfee c
      on     c.certino = b.compensateno
      where  a.Դϵͳ = '������'
      union
      select /*+parallel(c 8)*/a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
      join   prpjplanfeehis c
      on     c.certino = b.compensateno
      where  a.Դϵͳ = '������'
      --������Ԥ��
      union
      select a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
      join   prpjplanfee c
      on     c.certino = b.precompensateno
      where  a.Դϵͳ = '������'
      union
      select /*+parallel(c 8)*/a.claimno,nvl(c.paybatchno,c.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
      join   prpjplanfeehis c
      on     c.certino = b.precompensateno
      where  a.Դϵͳ = '������'
      --������
      union
      select a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    b.validstatus is null
      and    b.compensatemode <> '14'
      join   prplpayinfolist c
      on     b.compensateno = c.compensateno
      join   prpjplanfee d
      on     d.certino = c.payid
      where  a.Դϵͳ = '������'
      union
      select /*+parallel(d 8)*/a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplcompensate b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      and    b.validstatus is null
      and    b.compensatemode <> '14'
      join   prplpayinfolist c
      on     b.compensateno = c.compensateno
      join   prpjplanfeehis d
      on     d.certino = c.payid
      where  a.Դϵͳ = '������'
      --������Ԥ��
      union
      select a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      join   prplpayinfolist c
      on     b.precompensateno = c.compensateno
      join   prpjplanfee d
      on     d.certino = c.payid
      where  a.Դϵͳ = '������'
      union
      select /*+parallel(d 8)*/a.claimno,nvl(d.paybatchno,d.certino) as paybatchno
      from   lp_claim_renshang a
      join   prplprepay b
      on     a.claimno = b.claimno
      and    b.underwriteflag in ('1','3')
      join   prplpayinfolist c
      on     b.precompensateno = c.compensateno
      join   prpjplanfeehis d
      on     d.certino = c.payid
      where  a.Դϵͳ = '������';
    commit;

    delete from lp_car_zj;
    commit;
    insert into lp_car_zj
      select claimno,max(d_paysentdate) as d_paysentdate
      from
             (
              select /*+parallel(b 8)*/
                     a.claimno
                     ,b.c_memo
                     ,b.d_paysentdate
                     ,row_number() over(partition by a.claimno,b.c_memo order by b.d_paysentdate) as rn
              from   lp_car_zj_pre a
              join   reportnet.tse_payments b
              on     a.paybatchno = b.c_memo
              where  b.c_paystate in ('2','3','4')
             )
      where  rn = 1
      group by claimno;
    commit;
    
    -- �ո���ϵͳ֧��ʱ��
    delete from lp_car_realpaydate;
    commit;
    insert into lp_car_realpaydate
      select claimno,max(Realpaydate) as Realpaydate
      from
             (
              --������
              select /*+parallel(b 8)*/a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
              join   prpjrefrec c
              on     c.certino = b.compensateno
              where  a.Դϵͳ = '������'
              and    c.realpaydate is not null
              union
              select /*+parallel(b 8)*/
                     a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (substr(b.flag,4,1) <> '1' or b.flag is null) --��ҵ
              join   prpjrefrechis c
              on     c.certino = b.compensateno
              where  a.Դϵͳ = '������'
              and    c.realpaydate is not null
              --������Ԥ��
              union
              select /*+parallel(c 8)*/
                     a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
              join   prpjrefrec c
              on     c.certino = b.precompensateno
              where  a.Դϵͳ = '������'
              and    c.realpaydate is not null
              union
              select /*+parallel(b 8)*/
                     a.claimno
                     ,to_date(to_char(c.Realpaydate, 'yyyy-mm-dd') || ' ' || c.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    (b.compulsoryFlag = '0' or b.compulsoryFlag is null) --��ҵ
              join   prpjrefrechis c
              on     c.certino = b.precompensateno
              where  a.Դϵͳ = '������'
              and    c.realpaydate is not null
              --������
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    b.validstatus is null
              and    b.compensatemode <> '14'
              join   prplpayinfolist c
              on     b.compensateno = c.compensateno
              join   prpjrefrec d
              on     d.certino = c.payid
              where  a.Դϵͳ = '������'
              and    d.realpaydate is not null
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplcompensate b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              and    b.validstatus is null
              and    b.compensatemode <> '14'
              join   prplpayinfolist c
              on     b.compensateno = c.compensateno
              join   prpjrefrechis d
              on     d.certino = c.payid
              where  a.Դϵͳ = '������'
              and    d.realpaydate is not null
              --������Ԥ��
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              join   prplpayinfolist c
              on     b.precompensateno = c.compensateno
              join   prpjrefrec d
              on     d.certino = c.payid
              where  a.Դϵͳ = '������'
              and    d.realpaydate is not null
              union
              select a.claimno
                     ,to_date(to_char(d.Realpaydate, 'yyyy-mm-dd') || ' ' || d.Transtime, 'yyyy-mm-dd hh24:mi:ss') AS Realpaydate
              from   lp_claim_renshang a
              join   prplprepay b
              on     a.claimno = b.claimno
              and    b.underwriteflag in ('1','3')
              join   prplpayinfolist c
              on     b.precompensateno = c.compensateno
              join   prpjrefrechis d
              on     d.certino = c.payid
              where  a.Դϵͳ = '������'
              and    d.realpaydate is not null
             )
      group by claimno;
    commit;
---------------------------------------------------------------------------------
    --2����ҵ�����漰���˰�����������
    insert into lp_kpi
    select 2
           ,'��ҵ�����漰���˰�����������'
           ,'ȫ��'
           ,null
           ,null
           ,count(*)
    from   lp_claim_renshang a
    left join
           lp_car_zj b
    on     a.claimno = b.claimno
    left join
           lp_car_realpaydate c
    on     a.claimno = c.claimno
    where  trunc(nvl(b.d_paysentdate,c.realpaydate)) between trunc(p_date,'yyyy') and p_date; 
    commit;

    --3����ҵ�������˰�����Ԫ��
    insert into lp_kpi
    select 3
           ,'��ҵ�������˰�����Ԫ��'
           ,'ȫ��'
           ,null
           ,null
           ,sum(a.sumdutypaid)
    from   lp_claim_renshang a
    left join
           lp_car_zj b
    on     a.claimno = b.claimno
    left join
           lp_car_realpaydate c
    on     a.claimno = c.claimno
    where  trunc(nvl(b.d_paysentdate,c.realpaydate)) between trunc(p_date,'yyyy') and p_date; 
    commit;
  END IF;
END;

 