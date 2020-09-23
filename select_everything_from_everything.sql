set serveroutput on;

set lines 80 
set head off 
set colsep ','
set pages 0
set feed off

spool runme.sql

select 'set colsep '',''' from dual;
select 'set lines 9999' from dual;
select 'set head off' from dual;
select 'set pages 0' from dual;
select 'set feed off' from dual;

begin
    for table_rec in (select table_name from all_tables where owner='ROCKBANK') loop

           dbms_output.put_line('spool '||table_rec.table_name||'.csv');
           dbms_output.put_line('select * from '||table_rec.table_name||';');

    end loop;
end;
/

select ' spool off' from dual;
spool off;
set serveroutput off;
