-- ===========================================================================================================================

-- Author: Vikrant Dhimate
-- Create date: 28-06-2018
-- Description: The script after execution  removes all orphan snmp configurations, creates a dummy snmpconfiguration \
--              and associates it with existing orphan LI <provided as LI param while executing script >

-- ===========================================================================================================================

CREATE OR REPLACE FUNCTION Orphan_LI_UpdateSnmpConfig(_lseId text) RETURNS text AS $$
DECLARE
  snmpid text;
  snmpName text;
  currentTime BigInt;  
  entityupdate_cnt numeric;

BEGIN
  snmpid := md5(random()::text || clock_timestamp()::text)::uuid;
  snmpName := 'name123035334-1530090188764';
  currentTime := EXTRACT(epoch FROM CURRENT_TIMESTAMP) * 1000 + EXTRACT(milliseconds FROM CURRENT_TIMESTAMP);

  ALTER TABLE "crm-core".logicalswitchentity DISABLE TRIGGER ALL;
  ALTER TABLE "crm-core".snmp_configuration DISABLE TRIGGER ALL;

  --deletes all orphan snmp configurations
  DELETE FROM "crm-core".snmp_configuration  WHERE id  = snmpid OR id NOT IN
   (SELECT snmpconfiguration_id FROM "crm-core".logicalswitchentity UNION SELECT snmpconfiguration_id FROM "crm-core".logicalswitchtemplateentity);     
   
  --creates new dummy snmp configuration
  INSERT INTO "crm-core".snmp_configuration(id, createdtime, modifiedtime, name, enabled, v3enabled, readcommunity) 
                     VALUES(snmpid, currentTime, currentTime, snmpName, false, true, '');   
					 
  --updates orphan LI with dummy configuration					 
  UPDATE "crm-core".logicalswitchentity SET snmpconfiguration_id = snmpid WHERE id IN (_lseId);                            
  
  GET DIAGNOSTICS entityupdate_cnt = ROW_COUNT;

  ALTER TABLE "crm-core".snmp_configuration ENABLE TRIGGER ALL;
  ALTER TABLE "crm-core".logicalswitchentity ENABLE TRIGGER ALL; 
  
  IF entityupdate_cnt < 1 THEN
           RAISE EXCEPTION 'There is no LI with id %. Please verify LI id before executing script.', _lseId; 
  END IF; 
 
  RETURN 'Update Orphan LI with Snmp Configuration Completed'; 
  
  EXCEPTION 
    WHEN OTHERS THEN
     RAISE INFO 'Error Name:%',SQLERRM;
     RAISE INFO 'Error State:%', SQLSTATE;  
  
END;
$$ LANGUAGE plpgsql;


SELECT Orphan_LI_UpdateSnmpConfig(:LI);
DROP FUNCTION IF EXISTS Orphan_LI_UpdateSnmpConfig(_lseId text);
