SQL> set pagesize 5000
SQL> set pagesize 5000 linesize 160
SQL> select * from table(kt_unwrap.unwrap('DBMS_AUDIT_MGMT'));

COLUMN_VALUE                                                                                                                                                    
----------------------------------------------------------------------------------------------------------------------------------------------------------------
PACKAGE BODY dbms_audit_mgmt AS                                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PARTITION    CONSTANT PLS_INTEGER   := 1;                                                                                                                     
  UNPARTITION  CONSTANT PLS_INTEGER   := 2;                                                                                                                     
                                                                                                                                                                
  TAB_MOVE     CONSTANT VARCHAR2(25) := 'ORA$DAM_AUD_TAB_MOVE';                                                                                                 
  FIL_CLEAN    CONSTANT VARCHAR2(25) := 'ORA$DAM_OS_FILE_CLEANUP';                                                                                              
  UNIAUD_OP    CONSTANT VARCHAR2(50) := 'ORA$DAM_UNIFIED_AUDIT_TRAIL_OP';                                                                                       
                                                                                                                                                                
  M_TAB_LCK_HDL         VARCHAR2(200);                                                                                                                          
  M_FIL_LCK_HDL         VARCHAR2(200);                                                                                                                          
  M_UNIAUD_LCK_HDL      VARCHAR2(200);                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION PART_DISALLOWED                                                                                                                                      
    RETURN BOOLEAN;                                                                                                                                             
                                                                                                                                                                
  PROCEDURE MOVE_TABLESPACES                                                                                                                                    
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_LOCATION_VALUE IN VARCHAR2,                                                                                                            
             AUDIT_PART_CNT       NUMBER                                                                                                                        
            );                                                                                                                                                  
                                                                                                                                                                
  PROCEDURE MOVE_FGA_TABLESPACE                                                                                                                                 
            (TBS_NAME IN VARCHAR2);                                                                                                                             
                                                                                                                                                                
  PROCEDURE MODIFY_AUDIT_TRAIL                                                                                                                                  
            (TBSCHEMA                   IN VARCHAR2,                                                                                                            
             TABLENAME                  IN VARCHAR2,                                                                                                            
             TBSPACE                    IN VARCHAR2,                                                                                                            
             ACTION                     IN PLS_INTEGER,                                                                                                         
             DEFAULT_CLEANUP_INTERVAL   IN PLS_INTEGER := 0                                                                                                     
            );                                                                                                                                                  
                                                                                                                                                                
  FUNCTION TBS_SPACE_CHECK                                                                                                                                      
           (AUDIT_TRAIL_TBS            IN  VARCHAR2,                                                                                                            
            AUDIT_TABLE_OWNER          IN  VARCHAR2,                                                                                                            
            AUDIT_TABLE_NAME           IN  VARCHAR2,                                                                                                            
            FACTOR_NEW_RECS            IN  PLS_INTEGER,                                                                                                         
            SPACE_OCCUPIED             OUT NUMBER,                                                                                                              
            SPACE_REQUIRED             OUT NUMBER,                                                                                                              
            SPACE_AVAILABLE            OUT NUMBER                                                                                                               
           )                                                                                                                                                    
  RETURN   BOOLEAN;                                                                                                                                             
                                                                                                                                                                
  FUNCTION SHOULD_DBC_PROPOGATE                                                                                                                                 
           (CONTAINER                  IN PLS_INTEGER)                                                                                                          
  RETURN   BOOLEAN;                                                                                                                                             
                                                                                                                                                                
  PROCEDURE DO_DBC_PROPOGATE                                                                                                                                    
           (SQL_TEXT                  IN VARCHAR2);                                                                                                             
                                                                                                                                                                
  FUNCTION IS_READ_WRITE                                                                                                                                        
  RETURN   BOOLEAN;                                                                                                                                             
                                                                                                                                                                
  PROCEDURE CHNG_OLS_AUD_TAB                                                                                                                                    
           (TSTAMP_PART_MAXV          IN  TIMESTAMP,                                                                                                            
            TBSPACE_DEST              IN  VARCHAR2                                                                                                              
           );                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION IS_CLEANUP_INITIALIZED_11G                                                                                                                           
           (AUDIT_TRAIL_TYPE           IN PLS_INTEGER)                                                                                                          
  RETURN BOOLEAN;                                                                                                                                               
  PROCEDURE INIT_CLEANUP_11G                                                                                                                                    
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             DEFAULT_CLEANUP_INTERVAL   IN PLS_INTEGER                                                                                                          
            );                                                                                                                                                  
  PROCEDURE SET_AUDIT_TRAIL_LOCATION_11G                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_LOCATION_VALUE IN VARCHAR2                                                                                                             
            );                                                                                                                                                  
  PROCEDURE DEINIT_CLEANUP_11G                                                                                                                                  
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER);                                                                                                        
  PROCEDURE SET_AUDIT_TRAIL_PROPERTY_11G                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY_VALUE IN PLS_INTEGER                                                                                                          
            );                                                                                                                                                  
  PROCEDURE CLEAR_AUDIT_TRAIL_PROPERTY_11G                                                                                                                      
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             USE_DEFAULT_VALUES         IN BOOLEAN := FALSE                                                                                                     
            );                                                                                                                                                  
  PROCEDURE CLEAN_AUDIT_TRAIL_11G                                                                                                                               
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE                                                                                                      
            );                                                                                                                                                  
  PROCEDURE CREATE_PURGE_JOB_11G                                                                                                                                
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_INTERVAL IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2,                                                                                                            
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE,                                                                                                     
             CONTAINER                  IN PLS_INTEGER                                                                                                          
            );                                                                                                                                                  
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_AUDIT_TRAIL_LOCATION_ANG                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_LOCATION_VALUE IN VARCHAR2                                                                                                             
            );                                                                                                                                                  
  PROCEDURE SET_AUDIT_TRAIL_PROPERTY_ANG                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY_VALUE IN PLS_INTEGER                                                                                                          
            );                                                                                                                                                  
  PROCEDURE CLEAR_AUDIT_TRAIL_PROPERTY_ANG                                                                                                                      
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             USE_DEFAULT_VALUES         IN BOOLEAN := FALSE                                                                                                     
            );                                                                                                                                                  
  PROCEDURE CLEAN_AUDIT_TRAIL_ANG                                                                                                                               
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE                                                                                                      
            );                                                                                                                                                  
  PROCEDURE CREATE_PURGE_JOB_ANG                                                                                                                                
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_INTERVAL IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2,                                                                                                            
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE,                                                                                                     
             CONTAINER                  IN PLS_INTEGER                                                                                                          
            );                                                                                                                                                  
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE RAISE_ORA_ERROR                                                                                                                                     
            (ERROR_CODE      IN PLS_INTEGER,                                                                                                                    
             ERROR_ARGUMENT  IN VARCHAR2 := NULL                                                                                                                
            )                                                                                                                                                   
  IS                                                                                                                                                            
    EXTERNAL                                                                                                                                                    
      NAME "kzam_sig_err"                                                                                                                                       
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 ERROR_CODE UB2,                                                                                                                                
                   ERROR_CODE INDICATOR SB2,                                                                                                                    
                 ERROR_ARGUMENT STRING,                                                                                                                         
                   ERROR_ARGUMENT INDICATOR SB2                                                                                                                 
                );                                                                                                                                              
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE WRITE_TRACE_MESSAGE                                                                                                                                 
            (TRACE_LEVEL     IN PLS_INTEGER,                                                                                                                    
             TRACE_MESSAGE   IN VARCHAR2                                                                                                                        
            )                                                                                                                                                   
  IS                                                                                                                                                            
    EXTERNAL                                                                                                                                                    
      NAME "kzam_write_trace"                                                                                                                                   
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 TRACE_LEVEL UB2,                                                                                                                               
                   TRACE_LEVEL INDICATOR SB2,                                                                                                                   
                 TRACE_MESSAGE STRING,                                                                                                                          
                   TRACE_MESSAGE INDICATOR SB2                                                                                                                  
                );                                                                                                                                              
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE UPDATE_ATRAIL_PROP_SGA                                                                                                                              
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_VALUE          IN PLS_INTEGER := NULL                                                                                                  
            )                                                                                                                                                   
  IS EXTERNAL                                                                                                                                                   
    NAME "kzam_set_atrail_property"                                                                                                                             
    LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                                 
    WITH CONTEXT                                                                                                                                                
    PARAMETERS(CONTEXT,                                                                                                                                         
               AUDIT_TRAIL_TYPE UB2,                                                                                                                            
                 AUDIT_TRAIL_TYPE INDICATOR SB2,                                                                                                                
               AUDIT_TRAIL_PROPERTY UB2,                                                                                                                        
                 AUDIT_TRAIL_PROPERTY INDICATOR SB2,                                                                                                            
               AUDIT_TRAIL_VALUE UB2,                                                                                                                           
                 AUDIT_TRAIL_VALUE INDICATOR SB2                                                                                                                
              );                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAN_AUDIT_TRAIL_INT                                                                                                                               
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN                                                                                                              
            )                                                                                                                                                   
  IS LANGUAGE C                                                                                                                                                 
    NAME "kzam_clean_atrail"                                                                                                                                    
    LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                                 
    WITH CONTEXT                                                                                                                                                
    PARAMETERS(CONTEXT,                                                                                                                                         
               AUDIT_TRAIL_TYPE UB2,                                                                                                                            
                 AUDIT_TRAIL_TYPE INDICATOR SB2,                                                                                                                
               USE_LAST_ARCH_TIMESTAMP UB2,                                                                                                                     
                 USE_LAST_ARCH_TIMESTAMP INDICATOR SB2                                                                                                          
              );                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION GET_AUDIT_COMMIT_DELAY                                                                                                                               
  RETURN PLS_INTEGER                                                                                                                                            
  IS LANGUAGE C                                                                                                                                                 
      NAME "kzam_get_commit_delay"                                                                                                                              
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 RETURN       UB2);                                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE ADD_HIDDEN_COLUMNS                                                                                                                                  
            (TABLE_NAME   IN VARCHAR2,                                                                                                                          
             COLUMN_NAME  IN VARCHAR2,                                                                                                                          
             COLUMN_DTYPE IN VARCHAR2                                                                                                                           
            )                                                                                                                                                   
  IS LANGUAGE C                                                                                                                                                 
    NAME "kzam_add_hcol"                                                                                                                                        
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 TABLE_NAME STRING,                                                                                                                             
                   TABLE_NAME INDICATOR SB2,                                                                                                                    
                 COLUMN_NAME STRING,                                                                                                                            
                   COLUMN_NAME INDICATOR SB2,                                                                                                                   
                 COLUMN_DTYPE STRING,                                                                                                                           
                   COLUMN_DTYPE INDICATOR SB2                                                                                                                   
                 );                                                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION ENQUEUE_GET_REL                                                                                                                                      
           (AUDIT_TRAIL_TYPE       IN PLS_INTEGER,                                                                                                              
            ENQUEUE_OPERATION      IN PLS_INTEGER                                                                                                               
           )                                                                                                                                                    
  RETURN PLS_INTEGER                                                                                                                                            
  IS LANGUAGE C                                                                                                                                                 
      NAME "kzam_enqueue_get_rel"                                                                                                                               
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 AUDIT_TRAIL_TYPE UB2,                                                                                                                          
                   AUDIT_TRAIL_TYPE INDICATOR SB2,                                                                                                              
                 ENQUEUE_OPERATION UB2,                                                                                                                         
                   ENQUEUE_OPERATION INDICATOR SB2,                                                                                                             
                 RETURN       UB2);                                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SETUP_NG_AUDIT_TSPACE                                                                                                                               
           (TABLESPACE_NAME        IN VARCHAR2,                                                                                                                 
            TABLESPACE_TYPE        IN PLS_INTEGER)                                                                                                              
  IS LANGUAGE C                                                                                                                                                 
    NAME "kzam_setup_ang_trail"                                                                                                                                 
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 TABLESPACE_NAME STRING,                                                                                                                        
                   TABLESPACE_NAME INDICATOR SB2,                                                                                                               
                   TABLESPACE_NAME LENGTH UB4,                                                                                                                  
                 TABLESPACE_TYPE UB2,                                                                                                                           
                   TABLESPACE_TYPE INDICATOR SB2                                                                                                                
                 );                                                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE FLUSH_UNIFIED_AUDIT_TRAIL_INT                                                                                                                       
           (FLUSH_TYPE      IN PLS_INTEGER)                                                                                                                     
  IS LANGUAGE C                                                                                                                                                 
    NAME "kzam_flush_ang_trail"                                                                                                                                 
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 FLUSH_TYPE UB2,                                                                                                                                
                   FLUSH_TYPE INDICATOR SB2                                                                                                                     
                 );                                                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE LOAD_UNIFIED_AUDIT_FILES_INT                                                                                                                        
  IS LANGUAGE C                                                                                                                                                 
    NAME "kzam_load_ang_files"                                                                                                                                  
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT                                                                                                                                        
                 );                                                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE MOVE_STD_AUD_TABLESPACE                                                                                                                             
            (TBS_NAME IN VARCHAR2)                                                                                                                              
  IS LANGUAGE C                                                                                                                                                 
    NAME "kzam_move_aud_tablespace"                                                                                                                             
      LIBRARY DBMS_AUDIT_MGMT_LIB                                                                                                                               
      WITH CONTEXT                                                                                                                                              
      PARAMETERS(CONTEXT,                                                                                                                                       
                 TBS_NAME STRING, TBS_NAME LENGTH UB4,                                                                                                          
                 TBS_NAME INDICATOR SB2                                                                                                                         
                );                                                                                                                                              
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE INIT_CLEANUP                                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             DEFAULT_CLEANUP_INTERVAL   IN PLS_INTEGER,                                                                                                         
             CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_SQL_TXT   VARCHAR2(1024);                                                                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In init_cleanup');                                                                                                 
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: AUDIT_TRAIL_TYPE');                                                                                    
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
                                                                                                                                                                
      M_SQL_TXT := 'begin sys.dbms_audit_mgmt.init_cleanup(' ||                                                                                                 
                   AUDIT_TRAIL_TYPE || ', ' || DEFAULT_CLEANUP_INTERVAL ||                                                                                      
                   ', ' || CONTAINER_CURRENT || '); end;';                                                                                                      
      DO_DBC_PROPOGATE(M_SQL_TXT);                                                                                                                              
      RETURN;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    INIT_CLEANUP_11G(AUDIT_TRAIL_TYPE, DEFAULT_CLEANUP_INTERVAL);                                                                                               
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE DEINIT_CLEANUP                                                                                                                                      
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT)                                                                                    
  IS                                                                                                                                                            
    M_SQL_TXT   VARCHAR2(1024);                                                                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In deinit_cleanup');                                                                                               
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: AUDIT_TRAIL_TYPE');                                                                                    
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
                                                                                                                                                                
      M_SQL_TXT := 'begin sys.dbms_audit_mgmt.deinit_cleanup(' ||                                                                                               
                   AUDIT_TRAIL_TYPE || ', ' || CONTAINER_CURRENT || '); end;';                                                                                  
      DO_DBC_PROPOGATE(M_SQL_TXT);                                                                                                                              
      RETURN;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    DEINIT_CLEANUP_11G(AUDIT_TRAIL_TYPE);                                                                                                                       
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_AUDIT_TRAIL_LOCATION                                                                                                                            
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_LOCATION_VALUE IN VARCHAR2                                                                                                             
            )                                                                                                                                                   
  IS                                                                                                                                                            
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_audit_trail_location');                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      SET_AUDIT_TRAIL_LOCATION_ANG(AUDIT_TRAIL_TYPE,                                                                                                            
                                   AUDIT_TRAIL_LOCATION_VALUE);                                                                                                 
    ELSE                                                                                                                                                        
      SET_AUDIT_TRAIL_LOCATION_11G(AUDIT_TRAIL_TYPE,                                                                                                            
                                   AUDIT_TRAIL_LOCATION_VALUE);                                                                                                 
    END IF;                                                                                                                                                     
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_AUDIT_TRAIL_PROPERTY                                                                                                                            
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY_VALUE IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_audit_trail_property');                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      SET_AUDIT_TRAIL_PROPERTY_ANG(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY,                                                                                      
                                   AUDIT_TRAIL_PROPERTY_VALUE);                                                                                                 
    ELSE                                                                                                                                                        
      SET_AUDIT_TRAIL_PROPERTY_11G(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY,                                                                                      
                                   AUDIT_TRAIL_PROPERTY_VALUE);                                                                                                 
    END IF;                                                                                                                                                     
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAR_AUDIT_TRAIL_PROPERTY                                                                                                                          
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             USE_DEFAULT_VALUES         IN BOOLEAN := FALSE                                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In clear_audit_trail_property');                                                                                   
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      CLEAR_AUDIT_TRAIL_PROPERTY_ANG(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY,                                                                                    
                                     USE_DEFAULT_VALUES);                                                                                                       
    ELSE                                                                                                                                                        
      CLEAR_AUDIT_TRAIL_PROPERTY_11G(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY,                                                                                    
                                     USE_DEFAULT_VALUES);                                                                                                       
    END IF;                                                                                                                                                     
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_LAST_ARCHIVE_TIMESTAMP                                                                                                                          
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             LAST_ARCHIVE_TIME          IN TIMESTAMP,                                                                                                           
             RAC_INSTANCE_NUMBER        IN PLS_INTEGER := NULL,                                                                                                 
             CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_ROW_COUNT         NUMBER;                                                                                                                                 
    M_SETUP_COUNT       NUMBER;                                                                                                                                 
    M_ATRAIL_TYPE       NUMBER := AUDIT_TRAIL_TYPE;                                                                                                             
    M_MAX_RAC_INST      NUMBER;                                                                                                                                 
    M_RAC_INST_NO       NUMBER;                                                                                                                                 
    M_RAC_ENABLED       VARCHAR2(10);                                                                                                                           
    M_SQL_TXT           VARCHAR2(1024);                                                                                                                         
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                      
                        ' In set_last_archive_timestamp');                                                                                                      
                                                                                                                                                                
    IF LAST_ARCHIVE_TIME IS NULL THEN                                                                                                                           
      RAISE_ORA_ERROR(46250, 'LAST_ARCHIVE_TIME');                                                                                                              
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
                                                                                                                                                                
      M_SQL_TXT := 'begin sys.dbms_audit_mgmt.set_last_archive_timestamp('                                                                                      
                    || AUDIT_TRAIL_TYPE || ', ''' || LAST_ARCHIVE_TIME ||                                                                                       
                    ''', ' ;                                                                                                                                    
      IF RAC_INSTANCE_NUMBER IS NULL THEN                                                                                                                       
        M_SQL_TXT := M_SQL_TXT || 'null); end;';                                                                                                                
      ELSE                                                                                                                                                      
        M_SQL_TXT := M_SQL_TXT || RAC_INSTANCE_NUMBER || '); end;';                                                                                             
      END IF;                                                                                                                                                   
                                                                                                                                                                
      DO_DBC_PROPOGATE(M_SQL_TXT);                                                                                                                              
      RETURN;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                     
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                    
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED                                                                                                                   
    THEN                                                                                                                                                        
       NULL;                                                                                                                                                    
    ELSE                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    SELECT MAX(INSTANCE_NUMBER) INTO M_MAX_RAC_INST                                                                                                             
    FROM GV$INSTANCE;                                                                                                                                           
                                                                                                                                                                
    IF RAC_INSTANCE_NUMBER <= 0 OR                                                                                                                              
       RAC_INSTANCE_NUMBER > M_MAX_RAC_INST THEN                                                                                                                
      RAISE_ORA_ERROR(46250, 'RAC_INSTANCE_NUMBER');                                                                                                            
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_RAC_INST_NO := RAC_INSTANCE_NUMBER;                                                                                                                       
                                                                                                                                                                
                                                                                                                                                                
    SELECT VALUE INTO M_RAC_ENABLED FROM V$OPTION                                                                                                               
    WHERE PARAMETER = 'Real Application Clusters';                                                                                                              
                                                                                                                                                                
    IF M_RAC_ENABLED = 'TRUE' AND                                                                                                                               
       (AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                    
        AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML                                                                                                                      
) AND                                                                                                                                                           
       RAC_INSTANCE_NUMBER IS NULL THEN                                                                                                                         
                                                                                                                                                                
         RAISE_ORA_ERROR(46266, 'RAC_INSTANCE_NUMBER');                                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                     
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML                                                                                                                       
 THEN                                                                                                                                                           
       IF M_RAC_INST_NO IS NULL THEN                                                                                                                            
                                                                                                                                                                
         SELECT INSTANCE_NUMBER INTO M_RAC_INST_NO FROM V$INSTANCE;                                                                                             
       END IF;                                                                                                                                                  
    ELSE                                                                                                                                                        
                                                                                                                                                                
      M_RAC_INST_NO := 0;                                                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD                                                                                                                   
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = M_ATRAIL_TYPE                                                                                                                   
            AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                   
                                                                                                                                                                
      IF M_SETUP_COUNT <= 0                                                                                                                                     
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    MERGE INTO SYS.DAM_LAST_ARCH_TS$ D                                                                                                                          
    USING (SELECT COUNT(AUDIT_TRAIL_TYPE#) R_CNT                                                                                                                
           FROM SYS.DAM_LAST_ARCH_TS$                                                                                                                           
           WHERE RAC_INSTANCE# = M_RAC_INST_NO AND                                                                                                              
                 AUDIT_TRAIL_TYPE# = M_ATRAIL_TYPE) S                                                                                                           
    ON (S.R_CNT = 1)                                                                                                                                            
    WHEN MATCHED THEN                                                                                                                                           
       UPDATE SET D.LAST_ARCHIVE_TIMESTAMP = LAST_ARCHIVE_TIME                                                                                                  
       WHERE D.RAC_INSTANCE# = M_RAC_INST_NO AND                                                                                                                
             D.AUDIT_TRAIL_TYPE# = M_ATRAIL_TYPE                                                                                                                
    WHEN NOT MATCHED THEN                                                                                                                                       
       INSERT VALUES(M_ATRAIL_TYPE, M_RAC_INST_NO,                                                                                                              
                     LAST_ARCHIVE_TIME);                                                                                                                        
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAR_LAST_ARCHIVE_TIMESTAMP                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             RAC_INSTANCE_NUMBER        IN PLS_INTEGER := NULL,                                                                                                 
             CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_ROW_COUNT         NUMBER;                                                                                                                                 
    M_ATRAIL_TYPE       NUMBER := AUDIT_TRAIL_TYPE;                                                                                                             
    M_MAX_RAC_INST      NUMBER;                                                                                                                                 
    M_RAC_ENABLED       VARCHAR2(10);                                                                                                                           
    M_RAC_INST_NO       NUMBER;                                                                                                                                 
    M_SQL_TXT           VARCHAR2(1024);                                                                                                                         
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                      
                       ' In clear_last_archive_timestamp');                                                                                                     
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
                                                                                                                                                                
      M_SQL_TXT := 'begin sys.dbms_audit_mgmt.clear_last_archive_timestamp(' ||                                                                                 
                    AUDIT_TRAIL_TYPE || ', ';                                                                                                                   
      IF RAC_INSTANCE_NUMBER IS NULL THEN                                                                                                                       
        M_SQL_TXT := M_SQL_TXT || 'null); end;';                                                                                                                
      ELSE                                                                                                                                                      
        M_SQL_TXT := M_SQL_TXT || RAC_INSTANCE_NUMBER || '); end;';                                                                                             
      END IF;                                                                                                                                                   
                                                                                                                                                                
      DO_DBC_PROPOGATE(M_SQL_TXT);                                                                                                                              
      RETURN;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                     
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                    
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED                                                                                                                   
    THEN                                                                                                                                                        
      NULL;                                                                                                                                                     
    ELSE                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    SELECT MAX(INSTANCE_NUMBER) INTO M_MAX_RAC_INST                                                                                                             
    FROM GV$INSTANCE;                                                                                                                                           
                                                                                                                                                                
    IF RAC_INSTANCE_NUMBER <= 0 OR                                                                                                                              
       RAC_INSTANCE_NUMBER > M_MAX_RAC_INST THEN                                                                                                                
      RAISE_ORA_ERROR(46250, 'RAC_INSTANCE_NUMBER');                                                                                                            
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_RAC_INST_NO := RAC_INSTANCE_NUMBER;                                                                                                                       
                                                                                                                                                                
                                                                                                                                                                
    SELECT VALUE INTO M_RAC_ENABLED FROM V$OPTION                                                                                                               
    WHERE PARAMETER = 'Real Application Clusters';                                                                                                              
                                                                                                                                                                
    IF M_RAC_ENABLED = 'TRUE' AND                                                                                                                               
       (AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                    
        AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML                                                                                                                      
) AND                                                                                                                                                           
       RAC_INSTANCE_NUMBER IS NULL THEN                                                                                                                         
                                                                                                                                                                
        RAISE_ORA_ERROR(46266, 'RAC_INSTANCE_NUMBER');                                                                                                          
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                     
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML                                                                                                                       
 THEN                                                                                                                                                           
       IF M_RAC_INST_NO IS NULL THEN                                                                                                                            
                                                                                                                                                                
         SELECT INSTANCE_NUMBER INTO M_RAC_INST_NO FROM V$INSTANCE;                                                                                             
       END IF;                                                                                                                                                  
    ELSE                                                                                                                                                        
                                                                                                                                                                
      M_RAC_INST_NO := 0;                                                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
    DELETE FROM SYS.DAM_LAST_ARCH_TS$                                                                                                                           
    WHERE RAC_INSTANCE# = M_RAC_INST_NO AND                                                                                                                     
          AUDIT_TRAIL_TYPE# = M_ATRAIL_TYPE;                                                                                                                    
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAN_AUDIT_TRAIL                                                                                                                                   
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE,                                                                                                     
             CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_SQL_TXT           VARCHAR2(1024);                                                                                                                         
    M_BOOL_VAL          VARCHAR2(20);                                                                                                                           
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In clean_audit_trail');                                                                                            
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
                                                                                                                                                                
      IF USE_LAST_ARCH_TIMESTAMP = TRUE THEN                                                                                                                    
        M_BOOL_VAL := 'TRUE';                                                                                                                                   
      ELSE                                                                                                                                                      
        M_BOOL_VAL := 'FALSE';                                                                                                                                  
      END IF;                                                                                                                                                   
                                                                                                                                                                
      M_SQL_TXT := 'begin sys.dbms_audit_mgmt.clean_audit_trail(' ||                                                                                            
                    AUDIT_TRAIL_TYPE || ', ' || M_BOOL_VAL || ', ' ||                                                                                           
                    CONTAINER_CURRENT || '); end;';                                                                                                             
      DO_DBC_PROPOGATE(M_SQL_TXT);                                                                                                                              
      RETURN;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE IS NULL THEN                                                                                                                            
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL THEN                                                                                                                  
      CLEAN_AUDIT_TRAIL_ANG(AUDIT_TRAIL_TYPE, USE_LAST_ARCH_TIMESTAMP);                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE <> AUDIT_TRAIL_UNIFIED THEN                                                                                                             
      CLEAN_AUDIT_TRAIL_11G(AUDIT_TRAIL_TYPE, USE_LAST_ARCH_TIMESTAMP);                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CREATE_PURGE_JOB                                                                                                                                    
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_INTERVAL IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2,                                                                                                            
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE,                                                                                                     
             CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_PDB_NAME   VARCHAR2(200);                                                                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'In create_purge_job ');                                                                                             
                                                                                                                                                                
    IF CONTAINER = CONTAINER_ALL THEN                                                                                                                           
                                                                                                                                                                
      SELECT  SYS_CONTEXT('userenv', 'con_name') INTO M_PDB_NAME FROM DUAL;                                                                                     
      IF M_PDB_NAME <> 'CDB$ROOT' THEN                                                                                                                          
        RAISE_ORA_ERROR(65040, NULL);                                                                                                                           
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      CREATE_PURGE_JOB_ANG(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PURGE_INTERVAL,                                                                                        
                           AUDIT_TRAIL_PURGE_NAME,                                                                                                              
                           USE_LAST_ARCH_TIMESTAMP, CONTAINER);                                                                                                 
    ELSE                                                                                                                                                        
      CREATE_PURGE_JOB_11G(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PURGE_INTERVAL,                                                                                        
                           AUDIT_TRAIL_PURGE_NAME,                                                                                                              
                           USE_LAST_ARCH_TIMESTAMP, CONTAINER);                                                                                                 
    END IF;                                                                                                                                                     
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_PURGE_JOB_STATUS                                                                                                                                
            (AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2,                                                                                                            
             AUDIT_TRAIL_STATUS_VALUE   IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_JOBS             NUMBER;                                                                                                                                  
    M_NEW_JOB_NAME     VARCHAR2(100);                                                                                                                           
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_purge_job_status ');                                                                                        
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PURGE_NAME IS NULL OR                                                                                                                        
       LENGTH(AUDIT_TRAIL_PURGE_NAME) = 0 OR                                                                                                                    
       LENGTH(AUDIT_TRAIL_PURGE_NAME) > 100                                                                                                                     
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_NEW_JOB_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(AUDIT_TRAIL_PURGE_NAME);                                                                                    
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                       
    END;                                                                                                                                                        
                                                                                                                                                                
    IF AUDIT_TRAIL_STATUS_VALUE < PURGE_JOB_ENABLE OR                                                                                                           
       AUDIT_TRAIL_STATUS_VALUE > PURGE_JOB_DISABLE                                                                                                             
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_STATUS_VALUE');                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
    SELECT COUNT(JOB_NAME) INTO M_JOBS FROM SYS.DAM_CLEANUP_JOBS$ WHERE                                                                                         
    JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                                       
                                                                                                                                                                
    IF M_JOBS <= 0 THEN                                                                                                                                         
      RAISE_ORA_ERROR(46255);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    CASE                                                                                                                                                        
      WHEN AUDIT_TRAIL_STATUS_VALUE = PURGE_JOB_ENABLE THEN                                                                                                     
      BEGIN                                                                                                                                                     
        DBMS_SCHEDULER.ENABLE(M_NEW_JOB_NAME);                                                                                                                  
        UPDATE SYS.DAM_CLEANUP_JOBS$ SET JOB_STATUS = 1                                                                                                         
        WHERE JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                             
                                                                                                                                                                
      END;                                                                                                                                                      
                                                                                                                                                                
      WHEN AUDIT_TRAIL_STATUS_VALUE = PURGE_JOB_DISABLE THEN                                                                                                    
      BEGIN                                                                                                                                                     
        DBMS_SCHEDULER.DISABLE(M_NEW_JOB_NAME);                                                                                                                 
        UPDATE SYS.DAM_CLEANUP_JOBS$ SET JOB_STATUS = 0                                                                                                         
        WHERE JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                             
                                                                                                                                                                
      END;                                                                                                                                                      
                                                                                                                                                                
      ELSE                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_STATUS_VALUE');                                                                                                     
    END CASE;                                                                                                                                                   
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_PURGE_JOB_INTERVAL                                                                                                                              
            (AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2,                                                                                                            
             AUDIT_TRAIL_INTERVAL_VALUE IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_INTERVAL      VARCHAR2(200);                                                                                                                              
    M_JOBS          NUMBER;                                                                                                                                     
    M_NEW_JOB_NAME  VARCHAR2(100);                                                                                                                              
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_purge_job_interval ');                                                                                      
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PURGE_NAME IS NULL OR                                                                                                                        
       LENGTH(AUDIT_TRAIL_PURGE_NAME) = 0 OR                                                                                                                    
       LENGTH(AUDIT_TRAIL_PURGE_NAME) > 100                                                                                                                     
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_NEW_JOB_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(AUDIT_TRAIL_PURGE_NAME);                                                                                    
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                       
    END;                                                                                                                                                        
                                                                                                                                                                
    IF AUDIT_TRAIL_INTERVAL_VALUE <= 0 OR                                                                                                                       
       AUDIT_TRAIL_INTERVAL_VALUE >= 1000                                                                                                                       
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_INTERVAL_VALUE');                                                                                                     
    END IF;                                                                                                                                                     
                                                                                                                                                                
    SELECT COUNT(JOB_NAME) INTO M_JOBS FROM SYS.DAM_CLEANUP_JOBS$ WHERE                                                                                         
    JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                                       
                                                                                                                                                                
    IF M_JOBS <= 0 THEN                                                                                                                                         
      RAISE_ORA_ERROR(46255);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_INTERVAL := 'FREQ=HOURLY;INTERVAL='|| AUDIT_TRAIL_INTERVAL_VALUE;                                                                                         
                                                                                                                                                                
    DBMS_SCHEDULER.SET_ATTRIBUTE(M_NEW_JOB_NAME, 'REPEAT_INTERVAL',                                                                                             
                                 M_INTERVAL);                                                                                                                   
                                                                                                                                                                
    UPDATE SYS.DAM_CLEANUP_JOBS$                                                                                                                                
    SET JOB_INTERVAL = AUDIT_TRAIL_INTERVAL_VALUE,                                                                                                              
        JOB_FREQUENCY = M_INTERVAL                                                                                                                              
    WHERE JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                                 
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE DROP_PURGE_JOB                                                                                                                                      
            (AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2                                                                                                             
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_JOBS             NUMBER;                                                                                                                                  
    M_NEW_JOB_NAME     VARCHAR2(100);                                                                                                                           
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In drop_purge_job ');                                                                                              
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PURGE_NAME IS NULL OR                                                                                                                        
       LENGTH(AUDIT_TRAIL_PURGE_NAME) = 0 OR                                                                                                                    
       LENGTH(AUDIT_TRAIL_PURGE_NAME) > 100                                                                                                                     
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_NEW_JOB_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(AUDIT_TRAIL_PURGE_NAME);                                                                                    
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                       
    END;                                                                                                                                                        
                                                                                                                                                                
    SELECT COUNT(JOB_NAME) INTO M_JOBS FROM SYS.DAM_CLEANUP_JOBS$ WHERE                                                                                         
    JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                                       
                                                                                                                                                                
    IF M_JOBS <= 0 THEN                                                                                                                                         
      RAISE_ORA_ERROR(46255);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    DBMS_SCHEDULER.DROP_JOB(M_NEW_JOB_NAME);                                                                                                                    
                                                                                                                                                                
    DELETE FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                           
    WHERE JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                                 
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_DEBUG_LEVEL(DEBUG_LEVEL IN PLS_INTEGER := TRACE_LEVEL_ERROR)                                                                                    
  IS                                                                                                                                                            
    M_DEBUG_LEVEL     NUMBER := DEBUG_LEVEL;                                                                                                                    
  BEGIN                                                                                                                                                         
    IF DEBUG_LEVEL < TRACE_LEVEL_DEBUG OR                                                                                                                       
       DEBUG_LEVEL > TRACE_LEVEL_ERROR                                                                                                                          
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'DEBUG_LEVEL');                                                                                                                    
    END IF;                                                                                                                                                     
                                                                                                                                                                
    MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                          
    USING (SELECT COUNT(*) R_CNT                                                                                                                                
           FROM SYS.DAM_CONFIG_PARAM$                                                                                                                           
           WHERE PARAM_ID = TRACE_LEVEL                                                                                                                         
                 AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_ALL) S                                                                                                     
    ON (S.R_CNT = 1)                                                                                                                                            
    WHEN MATCHED THEN                                                                                                                                           
       UPDATE SET D.NUMBER_VALUE = M_DEBUG_LEVEL                                                                                                                
       WHERE D.PARAM_ID = TRACE_LEVEL                                                                                                                           
             AND D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_ALL                                                                                                          
    WHEN NOT MATCHED THEN                                                                                                                                       
       INSERT VALUES(TRACE_LEVEL, AUDIT_TRAIL_ALL, M_DEBUG_LEVEL,                                                                                               
                     NULL);                                                                                                                                     
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
    UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_ALL, TRACE_LEVEL);                                                                                                       
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION IS_CLEANUP_INITIALIZED                                                                                                                               
           (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                          
            CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT)                                                                                     
  RETURN BOOLEAN                                                                                                                                                
  IS                                                                                                                                                            
    M_RET_ARR   DBMS_SQL.VARCHAR2S;                                                                                                                             
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'In is_cleanup_initialized');                                                                                        
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: AUDIT_TRAIL_TYPE');                                                                                    
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
      RETURN NULL;                                                                                                                                              
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
                                                                                                                                                                
      RETURN IS_CLEANUP_INITIALIZED(AUDIT_TRAIL_TYPE, CONTAINER, M_RET_ARR);                                                                                    
    ELSE                                                                                                                                                        
      RETURN IS_CLEANUP_INITIALIZED_11G(AUDIT_TRAIL_TYPE);                                                                                                      
    END IF;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION IS_CLEANUP_INITIALIZED                                                                                                                               
           (AUDIT_TRAIL_TYPE           IN     PLS_INTEGER,                                                                                                      
            CONTAINER                  IN     PLS_INTEGER,                                                                                                      
            UNINITIALIZED_PDBS         IN OUT DBMS_SQL.VARCHAR2S)                                                                                               
  RETURN BOOLEAN                                                                                                                                                
  IS                                                                                                                                                            
    M_RET_VAL   BOOLEAN;                                                                                                                                        
    M_CURR_PDB  VARCHAR2(200);                                                                                                                                  
    M_PDB_NAME  VARCHAR2(200);                                                                                                                                  
    M_COUNTER   NUMBER;                                                                                                                                         
    CURSOR SEL_PDBS IS                                                                                                                                          
   SELECT NAME FROM V$CONTAINERS WHERE NAME <> 'PDB$SEED' ORDER BY CON_ID DESC;                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'In is_cleanup_initialized II ');                                                                                    
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_UNIFIED THEN                                                                                                              
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: AUDIT_TRAIL_TYPE');                                                                                    
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
      RETURN NULL;                                                                                                                                              
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_RET_VAL := TRUE;                                                                                                                                          
    M_COUNTER := 1;                                                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
    SELECT SYS_CONTEXT('userenv', 'con_name') INTO M_CURR_PDB FROM DUAL;                                                                                        
    IF M_CURR_PDB <> 'CDB$ROOT' THEN                                                                                                                            
      RAISE_ORA_ERROR(65040, NULL);                                                                                                                             
    END IF;                                                                                                                                                     
                                                                                                                                                                
    FOR PDBINFO IN SEL_PDBS LOOP                                                                                                                                
                                                                                                                                                                
      M_PDB_NAME := DBMS_ASSERT.ENQUOTE_NAME(PDBINFO.NAME, FALSE);                                                                                              
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Checking if (' ||                                                                                                 
                          M_PDB_NAME || ') is Initialized for Cleanup');                                                                                        
      EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || M_PDB_NAME;                                                                                         
                                                                                                                                                                
      BEGIN                                                                                                                                                     
        IF IS_CLEANUP_INITIALIZED_11G(AUDIT_TRAIL_TYPE) THEN                                                                                                    
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, '(' ||                                                                                                         
                              M_PDB_NAME || ') is Initialized for Cleanup');                                                                                    
        ELSE                                                                                                                                                    
          M_RET_VAL := FALSE;                                                                                                                                   
          UNINITIALIZED_PDBS(M_COUNTER) := M_PDB_NAME;                                                                                                          
          M_COUNTER := M_COUNTER + 1;                                                                                                                           
        END IF;                                                                                                                                                 
      EXCEPTION                                                                                                                                                 
        WHEN OTHERS THEN                                                                                                                                        
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                
                              'Exception encountered in ' || M_PDB_NAME);                                                                                       
          M_RET_VAL := FALSE;                                                                                                                                   
          UNINITIALIZED_PDBS(M_COUNTER) := M_PDB_NAME;                                                                                                          
          M_COUNTER := M_COUNTER + 1;                                                                                                                           
      END;                                                                                                                                                      
                                                                                                                                                                
    END LOOP;                                                                                                                                                   
                                                                                                                                                                
    RETURN M_RET_VAL;                                                                                                                                           
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE MOVE_DBAUDIT_TABLES                                                                                                                                 
            (AUDIT_TRAIL_TBS     IN VARCHAR2  DEFAULT 'SYSAUX'                                                                                                  
            )                                                                                                                                                   
  IS                                                                                                                                                            
  BEGIN                                                                                                                                                         
    SET_AUDIT_TRAIL_LOCATION_11G(AUDIT_TRAIL_DB_STD, AUDIT_TRAIL_TBS);                                                                                          
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE FLUSH_UNIFIED_AUDIT_TRAIL                                                                                                                           
            (FLUSH_TYPE         IN PLS_INTEGER := FLUSH_CURRENT_INSTANCE,                                                                                       
             CONTAINER          IN PLS_INTEGER := CONTAINER_CURRENT)                                                                                            
  IS                                                                                                                                                            
    M_SQL_TXT     VARCHAR2(1024);                                                                                                                               
  BEGIN                                                                                                                                                         
    IF IS_READ_WRITE THEN                                                                                                                                       
                                                                                                                                                                
      IF M_UNIAUD_LCK_HDL IS NULL THEN                                                                                                                          
        DBMS_LOCK.ALLOCATE_UNIQUE(UNIAUD_OP, M_UNIAUD_LCK_HDL);                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF DBMS_LOCK.REQUEST(M_UNIAUD_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                  
                             0 ) <> 0 THEN                                                                                                                      
          RAISE_ORA_ERROR(46277);                                                                                                                               
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
      M_SQL_TXT := 'begin sys.dbms_audit_mgmt.flush_unified_audit_trail(' ||                                                                                    
                   FLUSH_TYPE || '); end;';                                                                                                                     
      DO_DBC_PROPOGATE(M_SQL_TXT);                                                                                                                              
                                                                                                                                                                
      IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                          
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
                                                                                                                                                                
      RETURN;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    FLUSH_UNIFIED_AUDIT_TRAIL_INT(FLUSH_TYPE);                                                                                                                  
                                                                                                                                                                
    IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                            
        NULL;                                                                                                                                                   
    END IF;                                                                                                                                                     
    M_UNIAUD_LCK_HDL := NULL;                                                                                                                                   
                                                                                                                                                                
  EXCEPTION                                                                                                                                                     
    WHEN OTHERS THEN                                                                                                                                            
      IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                          
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
                                                                                                                                                                
      RAISE;                                                                                                                                                    
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION SHOULD_DBC_PROPOGATE                                                                                                                                 
           (CONTAINER                  IN PLS_INTEGER)                                                                                                          
  RETURN   BOOLEAN                                                                                                                                              
  IS                                                                                                                                                            
    M_PDB_COUNT     NUMBER;                                                                                                                                     
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In should_dbc_propogate');                                                                                         
                                                                                                                                                                
    IF CONTAINER = CONTAINER_CURRENT THEN                                                                                                                       
      RETURN FALSE;                                                                                                                                             
    END IF;                                                                                                                                                     
                                                                                                                                                                
    SELECT COUNT(*) INTO M_PDB_COUNT FROM V$PDBS;                                                                                                               
    IF M_PDB_COUNT > 0 THEN                                                                                                                                     
                                                                                                                                                                
      RETURN TRUE;                                                                                                                                              
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    RETURN FALSE;                                                                                                                                               
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE DO_DBC_PROPOGATE                                                                                                                                    
           (SQL_TEXT                  IN VARCHAR2)                                                                                                              
  IS                                                                                                                                                            
    M_ERR_OCC   BOOLEAN;                                                                                                                                        
    M_CURR_PDB  VARCHAR2(200);                                                                                                                                  
    M_PDB_NAME  VARCHAR2(200);                                                                                                                                  
    CURSOR SEL_PDBS IS                                                                                                                                          
   SELECT NAME FROM V$CONTAINERS WHERE NAME <> 'PDB$SEED' ORDER BY CON_ID DESC;                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In do_dbc_propogate');                                                                                             
                                                                                                                                                                
    IF SQL_TEXT IS NULL THEN                                                                                                                                    
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: SQL_TEXT');                                                                                            
      RAISE_ORA_ERROR(46250, 'SQL_TEXT');                                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    SELECT SYS_CONTEXT('userenv', 'con_name') INTO M_CURR_PDB FROM DUAL;                                                                                        
    IF M_CURR_PDB <> 'CDB$ROOT' THEN                                                                                                                            
      RAISE_ORA_ERROR(65040, NULL);                                                                                                                             
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_ERR_OCC := FALSE;                                                                                                                                         
                                                                                                                                                                
    FOR PDBINFO IN SEL_PDBS LOOP                                                                                                                                
                                                                                                                                                                
      M_PDB_NAME := DBMS_ASSERT.ENQUOTE_NAME(PDBINFO.NAME, FALSE);                                                                                              
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Executing (' ||                                                                                                   
                          SQL_TEXT || ') in '|| M_PDB_NAME);                                                                                                    
      EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || M_PDB_NAME;                                                                                         
                                                                                                                                                                
      BEGIN                                                                                                                                                     
        EXECUTE IMMEDIATE SQL_TEXT;                                                                                                                             
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Execution complete in '||                                                                                       
                            M_PDB_NAME);                                                                                                                        
      EXCEPTION                                                                                                                                                 
        WHEN OTHERS THEN                                                                                                                                        
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                
                              'Exception encountered in ' || M_PDB_NAME);                                                                                       
        M_ERR_OCC := TRUE;                                                                                                                                      
                                                                                                                                                                
      END;                                                                                                                                                      
                                                                                                                                                                
    END LOOP;                                                                                                                                                   
                                                                                                                                                                
    IF M_ERR_OCC = TRUE THEN                                                                                                                                    
      RAISE_ORA_ERROR(46273, NULL);                                                                                                                             
    END IF;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION IS_READ_WRITE                                                                                                                                        
  RETURN   BOOLEAN                                                                                                                                              
  IS                                                                                                                                                            
    IS_CDB_ENABLED     VARCHAR2(25);                                                                                                                            
    CONTAINER_MODE     VARCHAR2(25);                                                                                                                            
  BEGIN                                                                                                                                                         
    SELECT CDB INTO IS_CDB_ENABLED FROM V$DATABASE;                                                                                                             
    IF IS_CDB_ENABLED = 'YES' THEN                                                                                                                              
                                                                                                                                                                
      SELECT OPEN_MODE INTO CONTAINER_MODE FROM V$CONTAINERS WHERE                                                                                              
             NAME = UPPER(SYS_CONTEXT('USERENV', 'CON_NAME'));                                                                                                  
      IF CONTAINER_MODE = 'READ WRITE' THEN                                                                                                                     
        RETURN TRUE;                                                                                                                                            
      ELSE                                                                                                                                                      
        RETURN FALSE;                                                                                                                                           
      END IF;                                                                                                                                                   
    ELSE                                                                                                                                                        
                                                                                                                                                                
      SELECT OPEN_MODE INTO CONTAINER_MODE FROM V$DATABASE;                                                                                                     
      IF CONTAINER_MODE = 'READ WRITE' THEN                                                                                                                     
        RETURN TRUE;                                                                                                                                            
      ELSE                                                                                                                                                      
        RETURN FALSE;                                                                                                                                           
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE INIT_CLEANUP_11G                                                                                                                                    
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             DEFAULT_CLEANUP_INTERVAL   IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_AUD_STMT       VARCHAR2(1000);                                                                                                                            
    M_FGA_STMT       VARCHAR2(1000);                                                                                                                            
    M_TSTAMP_MAXV    TIMESTAMP;                                                                                                                                 
    M_TBSPACE        VARCHAR2(32);                                                                                                                              
    M_TEMP_VCHAR     VARCHAR2(32);                                                                                                                              
    M_TBS_STATUS     VARCHAR2(10);                                                                                                                              
    M_TBSCHEMA       VARCHAR2(32);                                                                                                                              
    IS_PART_NALL     BOOLEAN := PART_DISALLOWED();                                                                                                              
    TBS_HAS_SPACE    BOOLEAN;                                                                                                                                   
    M_SP_OCC_AUD     NUMBER;                                                                                                                                    
    M_SP_REQ_AUD     NUMBER;                                                                                                                                    
    M_SP_AVAIL_AUD   NUMBER;                                                                                                                                    
    M_SP_OCC_FGA     NUMBER;                                                                                                                                    
    M_SP_REQ_FGA     NUMBER;                                                                                                                                    
    M_SP_AVAIL_FGA   NUMBER;                                                                                                                                    
    M_MAX_TSTMP      TIMESTAMP;                                                                                                                                 
    M_OLS_INST       VARCHAR2(10);                                                                                                                              
    M_TRACE_MESSAGE  VARCHAR2(200);                                                                                                                             
    M_TBS_CHECK_DONE BOOLEAN := FALSE;                                                                                                                          
    M_TBS_TEMP       VARCHAR2(32);                                                                                                                              
    M_AUD_CURTBS     VARCHAR2(32);                                                                                                                              
    M_FGA_CURTBS     VARCHAR2(32);                                                                                                                              
    M_AUD_DSTTBS     VARCHAR2(32);                                                                                                                              
    M_FGA_DSTTBS     VARCHAR2(32);                                                                                                                              
    M_SETUP_COUNT    NUMBER;                                                                                                                                    
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In init_cleanup_11g');                                                                                             
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE > AUDIT_TRAIL_ALL THEN                                                                                                                  
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: AUDIT_TRAIL_TYPE');                                                                                    
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF DEFAULT_CLEANUP_INTERVAL < 1 OR                                                                                                                          
       DEFAULT_CLEANUP_INTERVAL > 999                                                                                                                           
    THEN                                                                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                    
                          'ORA-46251: DEFAULT_CLEANUP_INTERVAL');                                                                                               
      RAISE_ORA_ERROR(46251, 'DEFAULT_CLEANUP_INTERVAL');                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
    SELECT SYS_EXTRACT_UTC(SYSTIMESTAMP) INTO M_TSTAMP_MAXV                                                                                                     
    FROM DUAL;                                                                                                                                                  
                                                                                                                                                                
    M_TSTAMP_MAXV := M_TSTAMP_MAXV + (DEFAULT_CLEANUP_INTERVAL * 1/24);                                                                                         
                                                                                                                                                                
    M_TRACE_MESSAGE := 'Timestamp + Cleanup interval ' ||                                                                                                       
                       TO_CHAR(M_TSTAMP_MAXV);                                                                                                                  
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, M_TRACE_MESSAGE);                                                                                                    
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                                 
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT STRING_VALUE INTO M_TEMP_VCHAR FROM SYS.DAM_CONFIG_PARAM$                                                                                          
      WHERE PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                      
            AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD;                                                                                                        
      M_AUD_DSTTBS := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TEMP_VCHAR);                                                                                                
      M_AUD_DSTTBS := NLS_UPPER(M_AUD_DSTTBS);                                                                                                                  
                                                                                                                                                                
                                                                                                                                                                
      SELECT TABLESPACE_NAME INTO M_TBS_TEMP FROM DBA_TABLES WHERE                                                                                              
      TABLE_NAME='AUD$';                                                                                                                                        
      M_AUD_CURTBS := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                  
      M_AUD_CURTBS := NLS_UPPER(M_AUD_CURTBS);                                                                                                                  
                                                                                                                                                                
                                                                                                                                                                
      SELECT STRING_VALUE INTO M_TEMP_VCHAR FROM SYS.DAM_CONFIG_PARAM$                                                                                          
      WHERE PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                      
            AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD;                                                                                                        
      M_FGA_DSTTBS := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TEMP_VCHAR);                                                                                                
      M_FGA_DSTTBS := NLS_UPPER(M_FGA_DSTTBS);                                                                                                                  
                                                                                                                                                                
                                                                                                                                                                
      SELECT TABLESPACE_NAME INTO M_TBS_TEMP FROM DBA_TABLES WHERE                                                                                              
      TABLE_NAME='FGA_LOG$';                                                                                                                                    
      M_FGA_CURTBS := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                  
      M_FGA_CURTBS := NLS_UPPER(M_FGA_CURTBS);                                                                                                                  
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                       
                                                                                                                                                                
      IF M_SETUP_COUNT = 4                                                                                                                                      
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46263: AUDIT_TRAIL_ALL');                                                                                   
        RAISE_ORA_ERROR(46263);                                                                                                                                 
      ELSIF M_SETUP_COUNT < 4 AND M_SETUP_COUNT > 0                                                                                                             
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46265: AUDIT_TRAIL_ALL');                                                                                   
        RAISE_ORA_ERROR(46265);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD                                                                                                                 
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD                                                                                                            
             OR AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD);                                                                                                       
                                                                                                                                                                
      IF M_SETUP_COUNT = 2                                                                                                                                      
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46263: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46263);                                                                                                                                 
      ELSIF M_SETUP_COUNT < 2 AND M_SETUP_COUNT > 0                                                                                                             
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46265: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46265);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                  
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS                                                                                                                 
             OR AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML);                                                                                                           
                                                                                                                                                                
      IF M_SETUP_COUNT = 2                                                                                                                                      
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46263: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46263);                                                                                                                                 
      ELSIF M_SETUP_COUNT < 2 AND M_SETUP_COUNT > 0                                                                                                             
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46265: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46265);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSE                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE;                                                                                                               
                                                                                                                                                                
      IF M_SETUP_COUNT <> 0                                                                                                                                     
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46263: Type = ' || AUDIT_TRAIL_TYPE);                                                                                          
        RAISE_ORA_ERROR(46263);                                                                                                                                 
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF M_TAB_LCK_HDL IS NULL THEN                                                                                                                               
      DBMS_LOCK.ALLOCATE_UNIQUE(TAB_MOVE, M_TAB_LCK_HDL);                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF DBMS_LOCK.REQUEST(M_TAB_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                       
                         0 ) <> 0 THEN                                                                                                                          
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46268');                                                                                                      
      RAISE_ORA_ERROR(46268);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
                                                                                                                                                                
                                                                                                                                                                
      DBMS_INTERNAL_LOGSTDBY.LOCK_LSBY_META;                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                               
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        SELECT U.USERNAME INTO M_TBSCHEMA FROM OBJ$ O, DBA_USERS U                                                                                              
        WHERE O.NAME = 'AUD$' AND O.TYPE#=2 AND O.OWNER# = U.USER_ID                                                                                            
              AND O.REMOTEOWNER IS NULL AND O.LINKNAME IS NULL                                                                                                  
              AND U.USERNAME = 'SYS';                                                                                                                           
                                                                                                                                                                
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'AUD$: Source "'||                                                                                               
                          M_AUD_CURTBS || '" and Destination "' ||                                                                                              
                          M_AUD_DSTTBS || '".');                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
        BEGIN                                                                                                                                                   
          SELECT STATUS INTO M_TBS_STATUS FROM DBA_TABLESPACES                                                                                                  
          WHERE TABLESPACE_NAME = M_AUD_DSTTBS;                                                                                                                 
                                                                                                                                                                
          IF UPPER(M_TBS_STATUS) <> 'ONLINE' THEN                                                                                                               
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                              
                                'ORA-46262 - AUD Tablespace offline');                                                                                          
            RAISE_ORA_ERROR(46262, M_AUD_DSTTBS);                                                                                                               
          END IF;                                                                                                                                               
        EXCEPTION                                                                                                                                               
          WHEN OTHERS THEN                                                                                                                                      
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                              
                                'AUD Tablespace Status err');                                                                                                   
            RAISE;                                                                                                                                              
                                                                                                                                                                
        END;                                                                                                                                                    
                                                                                                                                                                
        IF M_AUD_CURTBS <> M_AUD_DSTTBS OR                                                                                                                      
           (M_AUD_CURTBS = 'SYSTEM' AND M_AUD_DSTTBS <> 'SYSTEM')                                                                                               
        THEN                                                                                                                                                    
                                                                                                                                                                
          TBS_HAS_SPACE := TBS_SPACE_CHECK(M_AUD_DSTTBS, M_TBSCHEMA, 'AUD$',                                                                                    
                                           5, M_SP_OCC_AUD, M_SP_REQ_AUD,                                                                                       
                                           M_SP_AVAIL_AUD);                                                                                                     
                                                                                                                                                                
          IF TBS_HAS_SPACE = FALSE THEN                                                                                                                         
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...1');                                                                                            
            RAISE_ORA_ERROR(46267, M_AUD_DSTTBS);                                                                                                               
          END IF;                                                                                                                                               
                                                                                                                                                                
          IF (AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                          
              AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL)                                                                                                               
             AND                                                                                                                                                
             (M_FGA_CURTBS <> M_FGA_DSTTBS OR                                                                                                                   
              (M_FGA_CURTBS = 'SYSTEM' AND M_FGA_DSTTBS <> 'SYSTEM'))                                                                                           
          THEN                                                                                                                                                  
                                                                                                                                                                
                                                                                                                                                                
            TBS_HAS_SPACE := TBS_SPACE_CHECK(M_FGA_DSTTBS, 'SYS', 'FGA_LOG$',                                                                                   
                                             5, M_SP_OCC_FGA, M_SP_REQ_FGA,                                                                                     
                                             M_SP_AVAIL_FGA);                                                                                                   
                                                                                                                                                                
            IF M_AUD_DSTTBS = M_FGA_DSTTBS THEN                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
               IF M_SP_REQ_AUD + M_SP_REQ_FGA > M_SP_AVAIL_AUD THEN                                                                                             
                 WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...2');                                                                                       
                 RAISE_ORA_ERROR(46267, M_AUD_DSTTBS);                                                                                                          
               END IF;                                                                                                                                          
            ELSE                                                                                                                                                
                                                                                                                                                                
               IF TBS_HAS_SPACE = FALSE THEN                                                                                                                    
                                                                                                                                                                
                 WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46262...3');                                                                                       
                 RAISE_ORA_ERROR(46262, M_AUD_DSTTBS);                                                                                                          
               END IF;                                                                                                                                          
            END IF;                                                                                                                                             
                                                                                                                                                                
            M_TBS_CHECK_DONE := TRUE;                                                                                                                           
          END IF;                                                                                                                                               
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_AUD_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 1);                                                                                                     
          DBMS_LOCK.SLEEP(3);                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
          MODIFY_AUDIT_TRAIL(M_TBSCHEMA, 'AUD$', M_AUD_DSTTBS, PARTITION,                                                                                       
                             DEFAULT_CLEANUP_INTERVAL);                                                                                                         
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_AUD_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 0);                                                                                                     
                                                                                                                                                                
        ELSE                                                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Not moving AUD$. '||                                                                                          
                              'Source and destination tablespace are same');                                                                                    
        END IF;                                                                                                                                                 
                                                                                                                                                                
        INSERT INTO SYS.DAM_CONFIG_PARAM$ VALUES                                                                                                                
        (CLEAN_UP_INTERVAL, AUDIT_TRAIL_AUD_STD,                                                                                                                
         DEFAULT_CLEANUP_INTERVAL, NULL);                                                                                                                       
                                                                                                                                                                
        COMMIT;                                                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
        UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_AUD_STD, CLEAN_UP_INTERVAL);                                                                                         
        DBMS_LOCK.SLEEP(5);                                                                                                                                     
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                               
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'FGA_LOG$: Source "'||                                                                                           
                            M_FGA_CURTBS || '" and Destination "' ||                                                                                            
                            M_FGA_DSTTBS || '".');                                                                                                              
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
        BEGIN                                                                                                                                                   
          SELECT STATUS INTO M_TBS_STATUS FROM DBA_TABLESPACES                                                                                                  
          WHERE TABLESPACE_NAME = M_FGA_DSTTBS;                                                                                                                 
                                                                                                                                                                
          IF UPPER(M_TBS_STATUS) <> 'ONLINE' THEN                                                                                                               
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                              
                                'ORA-46262 - FGA Tablespace offline');                                                                                          
            RAISE_ORA_ERROR(46262, M_FGA_DSTTBS);                                                                                                               
          END IF;                                                                                                                                               
        EXCEPTION                                                                                                                                               
          WHEN OTHERS THEN                                                                                                                                      
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'FGA Tablespace Status err');                                                                                  
          RAISE_ORA_ERROR(46262, M_FGA_DSTTBS);                                                                                                                 
        END;                                                                                                                                                    
                                                                                                                                                                
        IF M_FGA_CURTBS <> M_FGA_DSTTBS OR                                                                                                                      
           (M_FGA_CURTBS = 'SYSTEM' AND M_FGA_DSTTBS <> 'SYSTEM')                                                                                               
        THEN                                                                                                                                                    
                                                                                                                                                                
          IF M_TBS_CHECK_DONE = FALSE THEN                                                                                                                      
            TBS_HAS_SPACE := TBS_SPACE_CHECK(M_FGA_DSTTBS, 'SYS', 'FGA_LOG$',                                                                                   
                                             5, M_SP_OCC_FGA, M_SP_REQ_FGA,                                                                                     
                                             M_SP_AVAIL_FGA);                                                                                                   
                                                                                                                                                                
            IF TBS_HAS_SPACE = FALSE THEN                                                                                                                       
              WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'ORA-46267...4');                                                                                          
              RAISE_ORA_ERROR(46267, M_FGA_DSTTBS);                                                                                                             
            END IF;                                                                                                                                             
          END IF;                                                                                                                                               
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_FGA_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 1);                                                                                                     
          DBMS_LOCK.SLEEP(3);                                                                                                                                   
                                                                                                                                                                
          MODIFY_AUDIT_TRAIL('SYS', 'FGA_LOG$', M_FGA_DSTTBS, PARTITION,                                                                                        
                              DEFAULT_CLEANUP_INTERVAL);                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_FGA_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 0);                                                                                                     
        ELSE                                                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Not moving FGA_LOG$. '||                                                                                      
                              'Source and destination tablespace are same');                                                                                    
        END IF;                                                                                                                                                 
                                                                                                                                                                
        INSERT INTO SYS.DAM_CONFIG_PARAM$ VALUES                                                                                                                
        (CLEAN_UP_INTERVAL, AUDIT_TRAIL_FGA_STD,                                                                                                                
         DEFAULT_CLEANUP_INTERVAL, NULL);                                                                                                                       
                                                                                                                                                                
        COMMIT;                                                                                                                                                 
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                   
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                      
        USING (SELECT COUNT(PARAM_ID) RCOUNT                                                                                                                    
               FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
               WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS                                                                                                         
               AND PARAM_ID = CLEAN_UP_INTERVAL) S                                                                                                              
        ON (S.RCOUNT = 1)                                                                                                                                       
        WHEN MATCHED THEN                                                                                                                                       
          UPDATE SET D.NUMBER_VALUE = DEFAULT_CLEANUP_INTERVAL                                                                                                  
          WHERE D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS AND                                                                                                        
                D.PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                  
        WHEN NOT MATCHED THEN                                                                                                                                   
          INSERT VALUES(CLEAN_UP_INTERVAL, AUDIT_TRAIL_OS,                                                                                                      
              DEFAULT_CLEANUP_INTERVAL, NULL);                                                                                                                  
                                                                                                                                                                
        COMMIT;                                                                                                                                                 
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                  
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                      
        USING (SELECT COUNT(PARAM_ID) RCOUNT                                                                                                                    
               FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
               WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML                                                                                                        
               AND PARAM_ID = CLEAN_UP_INTERVAL) S                                                                                                              
        ON (S.RCOUNT = 1)                                                                                                                                       
        WHEN MATCHED THEN                                                                                                                                       
          UPDATE SET D.NUMBER_VALUE = DEFAULT_CLEANUP_INTERVAL                                                                                                  
          WHERE D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML AND                                                                                                       
                D.PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                  
        WHEN NOT MATCHED THEN                                                                                                                                   
          INSERT VALUES(CLEAN_UP_INTERVAL, AUDIT_TRAIL_XML,                                                                                                     
            DEFAULT_CLEANUP_INTERVAL, NULL);                                                                                                                    
                                                                                                                                                                
        COMMIT;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
      SYS.DBMS_INTERNAL_LOGSTDBY.UNLOCK_LSBY_META;                                                                                                              
                                                                                                                                                                
      IF DBMS_LOCK.RELEASE(M_TAB_LCK_HDL) <> 0 THEN                                                                                                             
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_TAB_LCK_HDL := NULL;                                                                                                                                    
                                                                                                                                                                
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                            
           AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                            
           AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                             
           AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                   
        THEN                                                                                                                                                    
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_DB_STD, AUD_TAB_MOVEMENT_FLAG, 0);                                                                                 
        END IF;                                                                                                                                                 
                                                                                                                                                                
        SYS.DBMS_INTERNAL_LOGSTDBY.UNLOCK_LSBY_META;                                                                                                            
                                                                                                                                                                
        IF DBMS_LOCK.RELEASE(M_TAB_LCK_HDL) <> 0 THEN                                                                                                           
          NULL;                                                                                                                                                 
        END IF;                                                                                                                                                 
        M_TAB_LCK_HDL := NULL;                                                                                                                                  
                                                                                                                                                                
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE DEINIT_CLEANUP_11G                                                                                                                                  
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER)                                                                                                         
  IS                                                                                                                                                            
    M_AUD_STMT       VARCHAR2(1000);                                                                                                                            
    M_FGA_STMT       VARCHAR2(1000);                                                                                                                            
    M_TSTAMP_MAXV    TIMESTAMP;                                                                                                                                 
    M_SETUP_COUNT    NUMBER;                                                                                                                                    
    M_TBSPACE        VARCHAR2(32);                                                                                                                              
    M_TBS_CUR        VARCHAR2(32);                                                                                                                              
    M_TBS_TEMP       VARCHAR2(32);                                                                                                                              
    M_TBSCHEMA       VARCHAR2(32);                                                                                                                              
    TBS_HAS_SPACE    BOOLEAN;                                                                                                                                   
    M_DUMMY          NUMBER;                                                                                                                                    
    M_MAX_TSTMP      TIMESTAMP;                                                                                                                                 
    M_TBS_STATUS     VARCHAR2(10);                                                                                                                              
    M_OLS_INST       VARCHAR2(10);                                                                                                                              
    M_TBS_CHECK_DONE BOOLEAN := FALSE;                                                                                                                          
    M_UNINITED_EXCP  EXCEPTION;                                                                                                                                 
    PRAGMA EXCEPTION_INIT(M_UNINITED_EXCP, -46258);                                                                                                             
  BEGIN                                                                                                                                                         
                                                                                                                                                                
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In deinit_cleanup_11g');                                                                                           
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE > AUDIT_TRAIL_ALL THEN                                                                                                                  
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: AUDIT_TRAIL_TYPE');                                                                                    
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                       
                                                                                                                                                                
      IF M_SETUP_COUNT = 0                                                                                                                                      
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46268: AUDIT_TRAIL_ALL');                                                                                   
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      ELSIF M_SETUP_COUNT < 4                                                                                                                                   
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46272: AUDIT_TRAIL_ALL');                                                                                   
        RAISE_ORA_ERROR(46272);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD                                                                                                                 
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD                                                                                                            
             OR AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD);                                                                                                       
                                                                                                                                                                
      IF M_SETUP_COUNT = 0                                                                                                                                      
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46258: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      ELSIF M_SETUP_COUNT < 2                                                                                                                                   
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46272: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46272);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                  
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS                                                                                                                 
             OR AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML);                                                                                                           
                                                                                                                                                                
      IF M_SETUP_COUNT = 0                                                                                                                                      
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46258: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      ELSIF M_SETUP_COUNT < 2                                                                                                                                   
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46272: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46272);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSE                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE;                                                                                                               
                                                                                                                                                                
      IF M_SETUP_COUNT = 0                                                                                                                                      
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'ORA-46258: AUDIT_TRAIL_DB_STD');                                                                                                   
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF M_TAB_LCK_HDL IS NULL THEN                                                                                                                               
      DBMS_LOCK.ALLOCATE_UNIQUE(TAB_MOVE, M_TAB_LCK_HDL);                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF DBMS_LOCK.REQUEST(M_TAB_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                       
                         0 ) <> 0 THEN                                                                                                                          
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46268');                                                                                                      
      RAISE_ORA_ERROR(46268);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
                                                                                                                                                                
                                                                                                                                                                
      DBMS_INTERNAL_LOGSTDBY.LOCK_LSBY_META;                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                               
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                               
        FROM SYS.DAM_CONFIG_PARAM$                                                                                                                              
        WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD                                                                                                           
              AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                 
        IF M_SETUP_COUNT <= 0                                                                                                                                   
        THEN                                                                                                                                                    
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46258...1');                                                                                              
          RAISE_ORA_ERROR(46258);                                                                                                                               
        END IF;                                                                                                                                                 
                                                                                                                                                                
        SELECT STRING_VALUE INTO M_TBS_TEMP FROM DAM_CONFIG_PARAM$                                                                                              
        WHERE PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                    
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD;                                                                                                      
        M_TBSPACE := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                   
        M_TBSPACE := NLS_UPPER(M_TBSPACE);                                                                                                                      
                                                                                                                                                                
        SELECT U.USERNAME INTO M_TBSCHEMA FROM OBJ$ O, DBA_USERS U                                                                                              
        WHERE O.NAME = 'AUD$' AND O.TYPE#=2 AND O.OWNER# = U.USER_ID                                                                                            
              AND O.REMOTEOWNER IS NULL AND O.LINKNAME IS NULL                                                                                                  
              AND U.USERNAME = 'SYS';                                                                                                                           
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
        BEGIN                                                                                                                                                   
          SELECT STATUS INTO M_TBS_STATUS FROM DBA_TABLESPACES                                                                                                  
          WHERE TABLESPACE_NAME = M_TBSPACE;                                                                                                                    
                                                                                                                                                                
          IF UPPER(M_TBS_STATUS) <> 'ONLINE' THEN                                                                                                               
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'AUD Tablespace offline');                                                                                   
            RAISE_ORA_ERROR(46262, M_TBSPACE);                                                                                                                  
          END IF;                                                                                                                                               
        EXCEPTION                                                                                                                                               
          WHEN OTHERS THEN                                                                                                                                      
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'AUD Tablespace error');                                                                                     
            RAISE_ORA_ERROR(46262, M_TBSPACE);                                                                                                                  
        END;                                                                                                                                                    
                                                                                                                                                                
        SELECT TABLESPACE_NAME INTO M_TBS_TEMP FROM DBA_TABLES WHERE                                                                                            
        TABLE_NAME='AUD$';                                                                                                                                      
        M_TBS_CUR := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                   
        M_TBS_CUR := NLS_UPPER(M_TBS_CUR);                                                                                                                      
                                                                                                                                                                
        IF M_TBS_CUR <> M_TBSPACE                                                                                                                               
        THEN                                                                                                                                                    
                                                                                                                                                                
          TBS_HAS_SPACE := TBS_SPACE_CHECK(M_TBSPACE, M_TBSCHEMA, 'AUD$',                                                                                       
                                           5, M_DUMMY, M_DUMMY, M_DUMMY);                                                                                       
                                                                                                                                                                
          IF TBS_HAS_SPACE = FALSE THEN                                                                                                                         
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...1');                                                                                            
            RAISE_ORA_ERROR(46267, M_TBSPACE);                                                                                                                  
          END IF;                                                                                                                                               
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
            DBMS_LOCK.SLEEP(3);                                                                                                                                 
            MODIFY_AUDIT_TRAIL(M_TBSCHEMA, 'AUD$', M_TBSPACE, UNPARTITION);                                                                                     
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
        END IF;                                                                                                                                                 
                                                                                                                                                                
        DELETE FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
        WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD                                                                                                           
              AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                 
                                                                                                                                                                
        COMMIT;                                                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
        UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_AUD_STD, CLEAN_UP_INTERVAL);                                                                                         
        DBMS_LOCK.SLEEP(5);                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                               
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                               
        FROM SYS.DAM_CONFIG_PARAM$                                                                                                                              
        WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD                                                                                                           
              AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                 
                                                                                                                                                                
        IF M_SETUP_COUNT <= 0                                                                                                                                   
        THEN                                                                                                                                                    
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46258...2');                                                                                              
          RAISE_ORA_ERROR(46258);                                                                                                                               
        END IF;                                                                                                                                                 
                                                                                                                                                                
        SELECT STRING_VALUE INTO M_TBS_TEMP FROM DAM_CONFIG_PARAM$                                                                                              
        WHERE PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                    
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD;                                                                                                      
        M_TBSPACE := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                   
        M_TBSPACE := NLS_UPPER(M_TBSPACE);                                                                                                                      
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
        BEGIN                                                                                                                                                   
          SELECT STATUS INTO M_TBS_STATUS FROM DBA_TABLESPACES                                                                                                  
          WHERE TABLESPACE_NAME = M_TBSPACE;                                                                                                                    
                                                                                                                                                                
          IF UPPER(M_TBS_STATUS) <> 'ONLINE' THEN                                                                                                               
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'FGA Tablespace offline');                                                                                   
            RAISE_ORA_ERROR(46262, M_TBSPACE);                                                                                                                  
          END IF;                                                                                                                                               
        EXCEPTION                                                                                                                                               
          WHEN OTHERS THEN                                                                                                                                      
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'FGA Tablespace error');                                                                                     
            RAISE_ORA_ERROR(46262, M_TBSPACE);                                                                                                                  
        END;                                                                                                                                                    
                                                                                                                                                                
        SELECT TABLESPACE_NAME INTO M_TBS_TEMP FROM DBA_TABLES WHERE                                                                                            
        TABLE_NAME='FGA_LOG$';                                                                                                                                  
        M_TBS_CUR := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                   
        M_TBS_CUR := NLS_UPPER(M_TBS_CUR);                                                                                                                      
                                                                                                                                                                
        IF M_TBS_CUR <> M_TBSPACE                                                                                                                               
        THEN                                                                                                                                                    
                                                                                                                                                                
          TBS_HAS_SPACE := TBS_SPACE_CHECK(M_TBSPACE, 'SYS', 'FGA_LOG$',                                                                                        
                                           5, M_DUMMY, M_DUMMY, M_DUMMY);                                                                                       
                                                                                                                                                                
          IF TBS_HAS_SPACE = FALSE THEN                                                                                                                         
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...2');                                                                                            
            RAISE_ORA_ERROR(46267, M_TBSPACE);                                                                                                                  
          END IF;                                                                                                                                               
                                                                                                                                                                
                                                                                                                                                                
          DBMS_LOCK.SLEEP(3);                                                                                                                                   
          MODIFY_AUDIT_TRAIL('SYS', 'FGA_LOG$', M_TBSPACE, UNPARTITION);                                                                                        
                                                                                                                                                                
        END IF;                                                                                                                                                 
                                                                                                                                                                
        DELETE FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
        WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD                                                                                                           
              AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                 
                                                                                                                                                                
        COMMIT;                                                                                                                                                 
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                   
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                               
        FROM SYS.DAM_CONFIG_PARAM$                                                                                                                              
        WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS                                                                                                                
              AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                 
                                                                                                                                                                
        IF M_SETUP_COUNT > 0                                                                                                                                    
        THEN                                                                                                                                                    
          DELETE FROM SYS.DAM_CONFIG_PARAM$                                                                                                                     
          WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS                                                                                                              
                AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                               
                                                                                                                                                                
          COMMIT;                                                                                                                                               
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                  
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                               
        FROM SYS.DAM_CONFIG_PARAM$                                                                                                                              
        WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML                                                                                                               
              AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                 
                                                                                                                                                                
        IF M_SETUP_COUNT > 0                                                                                                                                    
        THEN                                                                                                                                                    
          DELETE FROM SYS.DAM_CONFIG_PARAM$                                                                                                                     
          WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML                                                                                                             
                AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                               
                                                                                                                                                                
          COMMIT;                                                                                                                                               
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
      SYS.DBMS_INTERNAL_LOGSTDBY.UNLOCK_LSBY_META;                                                                                                              
                                                                                                                                                                
      IF DBMS_LOCK.RELEASE(M_TAB_LCK_HDL) <> 0 THEN                                                                                                             
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_TAB_LCK_HDL := NULL;                                                                                                                                    
                                                                                                                                                                
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        SYS.DBMS_INTERNAL_LOGSTDBY.UNLOCK_LSBY_META;                                                                                                            
                                                                                                                                                                
        IF DBMS_LOCK.RELEASE(M_TAB_LCK_HDL) <> 0 THEN                                                                                                           
          NULL;                                                                                                                                                 
        END IF;                                                                                                                                                 
        M_TAB_LCK_HDL := NULL;                                                                                                                                  
                                                                                                                                                                
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_AUDIT_TRAIL_LOCATION_11G                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_LOCATION_VALUE IN VARCHAR2                                                                                                             
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_PART_CNT       NUMBER;                                                                                                                                    
    M_TBSCHEMA       VARCHAR2(32);                                                                                                                              
    TBS_HAS_SPACE    BOOLEAN;                                                                                                                                   
    M_TBS_STATUS     VARCHAR2(10);                                                                                                                              
    M_TBS_NAME       VARCHAR2(32);                                                                                                                              
    M_TBS_TEMP       VARCHAR2(32);                                                                                                                              
    M_SP_OCC_AUD     NUMBER;                                                                                                                                    
    M_SP_REQ_AUD     NUMBER;                                                                                                                                    
    M_SP_AVAILABLE   NUMBER;                                                                                                                                    
    M_SP_OCC_FGA     NUMBER;                                                                                                                                    
    M_SP_REQ_FGA     NUMBER;                                                                                                                                    
    M_AUD_CURTBS     VARCHAR2(32);                                                                                                                              
    M_FGA_CURTBS     VARCHAR2(32);                                                                                                                              
    M_AUD_DSTTBS     VARCHAR2(32);                                                                                                                              
    M_FGA_DSTTBS     VARCHAR2(32);                                                                                                                              
    M_TBS_CHECK_DONE BOOLEAN := FALSE;                                                                                                                          
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_audit_trail_location_11g');                                                                                 
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                     
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                    
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                     
    THEN                                                                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-38430');                                                                                                      
      RAISE_ORA_ERROR(38430);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE > AUDIT_TRAIL_DB_STD                                                                                                                    
    THEN                                                                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: AUDIT_TRAIL_TYPE');                                                                                    
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_LOCATION_VALUE IS NULL OR                                                                                                                    
       LENGTH(AUDIT_TRAIL_LOCATION_VALUE) = 0 OR                                                                                                                
       LENGTH(AUDIT_TRAIL_LOCATION_VALUE) > 30                                                                                                                  
    THEN                                                                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                    
                          'ORA-46250: AUDIT_TRAIL_LOCATION_VALUE');                                                                                             
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_LOCATION_VALUE');                                                                                                     
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_TBS_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(AUDIT_TRAIL_LOCATION_VALUE);                                                                                    
      M_TBS_NAME := NLS_UPPER(M_TBS_NAME);                                                                                                                      
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: SQL_NAME');                                                                                          
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_LOCATION_VALUE');                                                                                                   
    END;                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    SELECT TABLESPACE_NAME INTO M_TBS_TEMP FROM DBA_TABLES WHERE                                                                                                
    TABLE_NAME='AUD$';                                                                                                                                          
    M_AUD_CURTBS := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                    
    M_AUD_CURTBS := NLS_UPPER(M_AUD_CURTBS);                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
    SELECT TABLESPACE_NAME INTO M_TBS_TEMP FROM DBA_TABLES WHERE                                                                                                
    TABLE_NAME='FGA_LOG$';                                                                                                                                      
    M_FGA_CURTBS := DBMS_ASSERT.SIMPLE_SQL_NAME(M_TBS_TEMP);                                                                                                    
    M_FGA_CURTBS := NLS_UPPER(M_FGA_CURTBS);                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      SELECT STATUS INTO M_TBS_STATUS FROM DBA_TABLESPACES                                                                                                      
      WHERE TABLESPACE_NAME = M_TBS_NAME;                                                                                                                       
                                                                                                                                                                
      IF UPPER(M_TBS_STATUS) <> 'ONLINE' THEN                                                                                                                   
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'TS offline');                                                                                                   
        RAISE_ORA_ERROR(46262, M_TBS_NAME);                                                                                                                     
      END IF;                                                                                                                                                   
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'TS error');                                                                                                     
        RAISE_ORA_ERROR(46262, M_TBS_NAME);                                                                                                                     
    END;                                                                                                                                                        
                                                                                                                                                                
    IF M_TAB_LCK_HDL IS NULL THEN                                                                                                                               
      DBMS_LOCK.ALLOCATE_UNIQUE(TAB_MOVE, M_TAB_LCK_HDL);                                                                                                       
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF DBMS_LOCK.REQUEST(M_TAB_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                       
                         0 ) <> 0 THEN                                                                                                                          
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46268');                                                                                                      
      RAISE_ORA_ERROR(46268);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
                                                                                                                                                                
                                                                                                                                                                
      DBMS_INTERNAL_LOGSTDBY.LOCK_LSBY_META;                                                                                                                    
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD                                                                                                                  
      THEN                                                                                                                                                      
        SELECT U.USERNAME INTO M_TBSCHEMA FROM OBJ$ O, DBA_USERS U                                                                                              
        WHERE O.NAME = 'AUD$' AND O.TYPE#=2 AND O.OWNER# = U.USER_ID                                                                                            
              AND O.REMOTEOWNER IS NULL AND O.LINKNAME IS NULL                                                                                                  
              AND U.USERNAME = 'SYS';                                                                                                                           
                                                                                                                                                                
        SELECT COUNT(PARTITION_POSITION) INTO M_PART_CNT                                                                                                        
        FROM SYS.DBA_TAB_PARTITIONS                                                                                                                             
        WHERE TABLE_OWNER = M_TBSCHEMA AND TABLE_NAME = 'AUD$';                                                                                                 
                                                                                                                                                                
        IF M_AUD_CURTBS <> M_TBS_NAME                                                                                                                           
        THEN                                                                                                                                                    
                                                                                                                                                                
          TBS_HAS_SPACE := TBS_SPACE_CHECK(M_TBS_NAME, M_TBSCHEMA, 'AUD$',                                                                                      
                                           5, M_SP_OCC_AUD, M_SP_REQ_AUD,                                                                                       
                                           M_SP_AVAILABLE);                                                                                                     
                                                                                                                                                                
          IF TBS_HAS_SPACE = FALSE THEN                                                                                                                         
            WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...1');                                                                                            
            RAISE_ORA_ERROR(46267, M_TBS_NAME);                                                                                                                 
          END IF;                                                                                                                                               
                                                                                                                                                                
          IF (AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD AND                                                                                                         
              M_FGA_CURTBS <> M_TBS_NAME)                                                                                                                       
          THEN                                                                                                                                                  
                                                                                                                                                                
                                                                                                                                                                
            TBS_HAS_SPACE := TBS_SPACE_CHECK(M_TBS_NAME, 'SYS', 'FGA_LOG$',                                                                                     
                                             5, M_SP_OCC_FGA, M_SP_REQ_FGA,                                                                                     
                                             M_SP_AVAILABLE);                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
            IF M_SP_REQ_AUD + M_SP_REQ_FGA > M_SP_AVAILABLE THEN                                                                                                
              WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...2');                                                                                          
              RAISE_ORA_ERROR(46267, M_TBS_NAME);                                                                                                               
            END IF;                                                                                                                                             
                                                                                                                                                                
            M_TBS_CHECK_DONE := TRUE;                                                                                                                           
          END IF;                                                                                                                                               
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_AUD_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 1);                                                                                                     
          DBMS_LOCK.SLEEP(3);                                                                                                                                   
                                                                                                                                                                
          MOVE_TABLESPACES(AUDIT_TRAIL_AUD_STD, M_TBS_NAME, M_PART_CNT);                                                                                        
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_AUD_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 0);                                                                                                     
        ELSE                                                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Not moving AUD$. '||                                                                                          
                              'Source and destination tablespace are same');                                                                                    
        END IF;                                                                                                                                                 
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD                                                                                                                  
      THEN                                                                                                                                                      
        SELECT COUNT(PARTITION_POSITION) INTO M_PART_CNT                                                                                                        
        FROM SYS.DBA_TAB_PARTITIONS                                                                                                                             
        WHERE TABLE_OWNER = 'SYS' AND TABLE_NAME = 'FGA_LOG$';                                                                                                  
                                                                                                                                                                
        IF M_FGA_CURTBS <> M_TBS_NAME                                                                                                                           
        THEN                                                                                                                                                    
                                                                                                                                                                
          IF M_TBS_CHECK_DONE = FALSE THEN                                                                                                                      
            TBS_HAS_SPACE := TBS_SPACE_CHECK(M_TBS_NAME, 'SYS', 'FGA_LOG$',                                                                                     
                                             5, M_SP_OCC_FGA, M_SP_REQ_FGA,                                                                                     
                                             M_SP_AVAILABLE);                                                                                                   
                                                                                                                                                                
            IF TBS_HAS_SPACE = FALSE THEN                                                                                                                       
              WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...3');                                                                                          
              RAISE_ORA_ERROR(46267, M_TBS_NAME);                                                                                                               
            END IF;                                                                                                                                             
          END IF;                                                                                                                                               
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_FGA_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 1);                                                                                                     
          DBMS_LOCK.SLEEP(3);                                                                                                                                   
                                                                                                                                                                
          MOVE_TABLESPACES(AUDIT_TRAIL_FGA_STD, M_TBS_NAME, M_PART_CNT);                                                                                        
                                                                                                                                                                
                                                                                                                                                                
          UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_FGA_STD,                                                                                                           
                                 AUD_TAB_MOVEMENT_FLAG, 0);                                                                                                     
        ELSE                                                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Not moving FGA_LOG$. '||                                                                                      
                              'Source and destination tablespace are same');                                                                                    
        END IF;                                                                                                                                                 
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
      SYS.DBMS_INTERNAL_LOGSTDBY.UNLOCK_LSBY_META;                                                                                                              
                                                                                                                                                                
      IF DBMS_LOCK.RELEASE(M_TAB_LCK_HDL) <> 0 THEN                                                                                                             
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_TAB_LCK_HDL := NULL;                                                                                                                                    
                                                                                                                                                                
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
                                                                                                                                                                
        UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_DB_STD, AUD_TAB_MOVEMENT_FLAG, 0);                                                                                   
                                                                                                                                                                
        SYS.DBMS_INTERNAL_LOGSTDBY.UNLOCK_LSBY_META;                                                                                                            
                                                                                                                                                                
        IF DBMS_LOCK.RELEASE(M_TAB_LCK_HDL) <> 0 THEN                                                                                                           
          NULL;                                                                                                                                                 
        END IF;                                                                                                                                                 
        M_TAB_LCK_HDL := NULL;                                                                                                                                  
                                                                                                                                                                
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_AUDIT_TRAIL_PROPERTY_11G                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY_VALUE IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_AUD_TRAIL_TYP     NUMBER := AUDIT_TRAIL_TYPE;                                                                                                             
    M_ALL_TRAIL_CNT     NUMBER;                                                                                                                                 
    M_AUD_PROP          BOOLEAN := FALSE;                                                                                                                       
    M_FGA_PROP          BOOLEAN := FALSE;                                                                                                                       
    M_OS_PROP           BOOLEAN := FALSE;                                                                                                                       
    M_XML_PROP          BOOLEAN := FALSE;                                                                                                                       
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_audit_trail_property ');                                                                                    
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY < OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY > CLEAN_UP_INTERVAL                                                                                                                 
    THEN                                                                                                                                                        
      IF AUDIT_TRAIL_PROPERTY = DB_DELETE_BATCH_SIZE OR                                                                                                         
         AUDIT_TRAIL_PROPERTY = FILE_DELETE_BATCH_SIZE                                                                                                          
      THEN                                                                                                                                                      
         NULL;                                                                                                                                                  
                                                                                                                                                                
      ELSE                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PROPERTY');                                                                                                         
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE                                                                                                                   
    THEN                                                                                                                                                        
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                   
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                  
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                   
      THEN                                                                                                                                                      
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
        IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                 
        THEN                                                                                                                                                    
          SELECT COUNT(PARAM_ID) INTO M_ALL_TRAIL_CNT                                                                                                           
          FROM SYS.DAM_CONFIG_PARAM$                                                                                                                            
          WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                 
                AND (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS OR                                                                                                      
                     AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML)                                                                                                       
                AND NUMBER_VALUE <> 0;                                                                                                                          
        ELSE                                                                                                                                                    
          SELECT COUNT(PARAM_ID) INTO M_ALL_TRAIL_CNT                                                                                                           
          FROM SYS.DAM_CONFIG_PARAM$                                                                                                                            
          WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                 
                AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FILES                                                                                                       
                AND NUMBER_VALUE <> 0;                                                                                                                          
        END IF;                                                                                                                                                 
                                                                                                                                                                
        IF M_ALL_TRAIL_CNT >= 1 THEN                                                                                                                            
                                                                                                                                                                
          RAISE_ORA_ERROR(46253);                                                                                                                               
        END IF;                                                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
      ELSE                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                             
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE                                                                                                                
      THEN                                                                                                                                                      
        IF AUDIT_TRAIL_PROPERTY_VALUE < 1 OR                                                                                                                    
           AUDIT_TRAIL_PROPERTY_VALUE > 2000000                                                                                                                 
        THEN                                                                                                                                                    
          RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_PROPERTY');                                                                                                       
        END IF;                                                                                                                                                 
      ELSIF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE                                                                                                              
      THEN                                                                                                                                                      
        IF AUDIT_TRAIL_PROPERTY_VALUE < 1 OR                                                                                                                    
           AUDIT_TRAIL_PROPERTY_VALUE > 497                                                                                                                     
        THEN                                                                                                                                                    
          RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_PROPERTY');                                                                                                       
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS THEN                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
         UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                           
         SET NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                          
         WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                  
               AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS;                                                                                                          
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML THEN                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
         UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                           
         SET NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                          
         WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                  
               AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML;                                                                                                         
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
    ELSIF AUDIT_TRAIL_PROPERTY = CLEAN_UP_INTERVAL                                                                                                              
    THEN                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE > AUDIT_TRAIL_ALL                                                                                                                     
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                             
      ELSE                                                                                                                                                      
        IF AUDIT_TRAIL_PROPERTY_VALUE < 1 OR                                                                                                                    
           AUDIT_TRAIL_PROPERTY_VALUE > 999                                                                                                                     
        THEN                                                                                                                                                    
          RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_PROPERTY');                                                                                                       
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      M_ALL_TRAIL_CNT := 0;                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL OR                                                                                                                  
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD                                                                                                                  
      THEN                                                                                                                                                      
                                                                                                                                                                
        SELECT COUNT(PARAM_ID) INTO M_ALL_TRAIL_CNT                                                                                                             
        FROM SYS.DAM_CONFIG_PARAM$                                                                                                                              
        WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                      
              AND (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD OR                                                                                                   
                   AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD);                                                                                                    
                                                                                                                                                                
        IF M_ALL_TRAIL_CNT != 2 THEN                                                                                                                            
          RAISE_ORA_ERROR(46258);                                                                                                                               
        END IF;                                                                                                                                                 
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                           
            AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD                                                                                                              
      THEN                                                                                                                                                      
                                                                                                                                                                
        SELECT COUNT(PARAM_ID) INTO M_ALL_TRAIL_CNT                                                                                                             
        FROM SYS.DAM_CONFIG_PARAM$                                                                                                                              
        WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                      
              AND AUDIT_TRAIL_TYPE# = M_AUD_TRAIL_TYP;                                                                                                          
                                                                                                                                                                
        IF M_ALL_TRAIL_CNT != 1 THEN                                                                                                                            
          RAISE_ORA_ERROR(46258);                                                                                                                               
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL THEN                                                                                                                
         M_AUD_PROP := TRUE;                                                                                                                                    
         M_FGA_PROP := TRUE;                                                                                                                                    
         M_OS_PROP  := TRUE;                                                                                                                                    
         M_XML_PROP := TRUE;                                                                                                                                    
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD THEN                                                                                                          
         M_AUD_PROP := TRUE;                                                                                                                                    
         M_FGA_PROP := TRUE;                                                                                                                                    
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES THEN                                                                                                           
         M_OS_PROP := TRUE;                                                                                                                                     
         M_XML_PROP := TRUE;                                                                                                                                    
      ELSE                                                                                                                                                      
        CASE                                                                                                                                                    
          WHEN AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD THEN                                                                                                      
            M_AUD_PROP := TRUE;                                                                                                                                 
          WHEN AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD THEN                                                                                                      
            M_FGA_PROP := TRUE;                                                                                                                                 
          WHEN AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS THEN                                                                                                           
            M_OS_PROP := TRUE;                                                                                                                                  
          WHEN AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML THEN                                                                                                          
            M_XML_PROP := TRUE;                                                                                                                                 
        END CASE;                                                                                                                                               
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF M_AUD_PROP = TRUE THEN                                                                                                                                 
        MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                      
        USING (SELECT COUNT(PARAM_ID) RCOUNT                                                                                                                    
               FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
               WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                               
                   AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD) S                                                                                               
        ON (S.RCOUNT = 1)                                                                                                                                       
        WHEN MATCHED THEN                                                                                                                                       
          UPDATE SET D.NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                
          WHERE D.PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                  
                AND D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD                                                                                                   
        WHEN NOT MATCHED THEN                                                                                                                                   
          INSERT VALUES(CLEAN_UP_INTERVAL, AUDIT_TRAIL_AUD_STD,                                                                                                 
                        AUDIT_TRAIL_PROPERTY_VALUE, NULL);                                                                                                      
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF M_FGA_PROP = TRUE THEN                                                                                                                                 
        MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                      
        USING (SELECT COUNT(PARAM_ID) RCOUNT                                                                                                                    
               FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
               WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                               
                   AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD) S                                                                                               
        ON (S.RCOUNT = 1)                                                                                                                                       
        WHEN MATCHED THEN                                                                                                                                       
          UPDATE SET D.NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                
          WHERE D.PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                  
                AND D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD                                                                                                   
        WHEN NOT MATCHED THEN                                                                                                                                   
          INSERT VALUES(CLEAN_UP_INTERVAL, AUDIT_TRAIL_FGA_STD,                                                                                                 
                        AUDIT_TRAIL_PROPERTY_VALUE, NULL);                                                                                                      
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF M_OS_PROP = TRUE THEN                                                                                                                                  
        MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                      
        USING (SELECT COUNT(PARAM_ID) RCOUNT                                                                                                                    
               FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
               WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                               
                   AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS) S                                                                                                    
        ON (S.RCOUNT = 1)                                                                                                                                       
        WHEN MATCHED THEN                                                                                                                                       
          UPDATE SET D.NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                
          WHERE D.PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                  
                AND D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS                                                                                                        
        WHEN NOT MATCHED THEN                                                                                                                                   
          INSERT VALUES(CLEAN_UP_INTERVAL, AUDIT_TRAIL_OS,                                                                                                      
                        AUDIT_TRAIL_PROPERTY_VALUE, NULL);                                                                                                      
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF M_XML_PROP = TRUE THEN                                                                                                                                 
        MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                      
        USING (SELECT COUNT(PARAM_ID) RCOUNT                                                                                                                    
               FROM SYS.DAM_CONFIG_PARAM$                                                                                                                       
               WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                               
                   AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML) S                                                                                                   
        ON (S.RCOUNT = 1)                                                                                                                                       
        WHEN MATCHED THEN                                                                                                                                       
          UPDATE SET D.NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                
          WHERE D.PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                  
                AND D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML                                                                                                       
        WHEN NOT MATCHED THEN                                                                                                                                   
          INSERT VALUES(CLEAN_UP_INTERVAL, AUDIT_TRAIL_XML,                                                                                                     
                        AUDIT_TRAIL_PROPERTY_VALUE, NULL);                                                                                                      
      END IF;                                                                                                                                                   
                                                                                                                                                                
    ELSIF AUDIT_TRAIL_PROPERTY = DB_DELETE_BATCH_SIZE                                                                                                           
    THEN                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE > AUDIT_TRAIL_FGA_STD                                                                                                                 
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                             
      ELSE                                                                                                                                                      
        IF AUDIT_TRAIL_PROPERTY_VALUE < 100 OR                                                                                                                  
           AUDIT_TRAIL_PROPERTY_VALUE > 1000000                                                                                                                 
        THEN                                                                                                                                                    
          RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_PROPERTY');                                                                                                       
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD THEN                                                                                                            
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                           
        WHERE PARAM_ID = DB_DELETE_BATCH_SIZE                                                                                                                   
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD;                                                                                                      
                                                                                                                                                                
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD THEN                                                                                                         
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                           
        WHERE PARAM_ID = DB_DELETE_BATCH_SIZE                                                                                                                   
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD;                                                                                                      
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
    ELSIF AUDIT_TRAIL_PROPERTY = FILE_DELETE_BATCH_SIZE                                                                                                         
    THEN                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_OS OR                                                                                                                   
         AUDIT_TRAIL_TYPE > AUDIT_TRAIL_XML                                                                                                                     
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                             
      ELSE                                                                                                                                                      
        IF AUDIT_TRAIL_PROPERTY_VALUE < 100 OR                                                                                                                  
           AUDIT_TRAIL_PROPERTY_VALUE > 1000000                                                                                                                 
        THEN                                                                                                                                                    
          RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_PROPERTY');                                                                                                       
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS THEN                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                           
        WHERE PARAM_ID = FILE_DELETE_BATCH_SIZE                                                                                                                 
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS;                                                                                                           
                                                                                                                                                                
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML THEN                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                           
        WHERE PARAM_ID = FILE_DELETE_BATCH_SIZE                                                                                                                 
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML;                                                                                                          
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE OR                                                                                                                
       AUDIT_TRAIL_PROPERTY = DB_DELETE_BATCH_SIZE OR                                                                                                           
       AUDIT_TRAIL_PROPERTY = FILE_DELETE_BATCH_SIZE                                                                                                            
    THEN                                                                                                                                                        
                                                                                                                                                                
      UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY);                                                                                           
    END IF;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAR_AUDIT_TRAIL_PROPERTY_11G                                                                                                                      
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             USE_DEFAULT_VALUES         IN BOOLEAN := FALSE                                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_AUD_TRAIL_TYP     NUMBER := AUDIT_TRAIL_TYPE;                                                                                                             
    M_ALL_TRAIL_CNT     NUMBER;                                                                                                                                 
    M_PROP_VALUE        NUMBER;                                                                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                      
                        ' In clear_audit_trail_property_11g');                                                                                                  
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = CLEAN_UP_INTERVAL                                                                                                                 
    THEN                                                                                                                                                        
                                                                                                                                                                
      RAISE_ORA_ERROR(46257, 'CLEAN_UP_INTERVAL');                                                                                                              
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY < OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY > OS_FILE_MAX_AGE                                                                                                                   
    THEN                                                                                                                                                        
      IF AUDIT_TRAIL_PROPERTY = DB_DELETE_BATCH_SIZE OR                                                                                                         
         AUDIT_TRAIL_PROPERTY = AUD_TAB_MOVEMENT_FLAG                                                                                                           
      THEN                                                                                                                                                      
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
         NULL;                                                                                                                                                  
                                                                                                                                                                
      ELSE                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PROPERTY');                                                                                                         
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE                                                                                                                   
    THEN                                                                                                                                                        
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                   
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                  
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                   
      THEN                                                                                                                                                      
        NULL;                                                                                                                                                   
      ELSE                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                             
      END IF;                                                                                                                                                   
                                                                                                                                                                
    ELSIF AUDIT_TRAIL_PROPERTY = DB_DELETE_BATCH_SIZE                                                                                                           
    THEN                                                                                                                                                        
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD                                                                                                                 
      THEN                                                                                                                                                      
        NULL;                                                                                                                                                   
      ELSE                                                                                                                                                      
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                             
      END IF;                                                                                                                                                   
                                                                                                                                                                
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE                                                                                                                   
    THEN                                                                                                                                                        
                                                                                                                                                                
      IF USE_DEFAULT_VALUES = FALSE THEN                                                                                                                        
        M_PROP_VALUE := 0;                                                                                                                                      
      ELSE                                                                                                                                                      
        CASE                                                                                                                                                    
          WHEN AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE THEN                                                                                                     
             M_PROP_VALUE := 10000;                                                                                                                             
          WHEN AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE THEN                                                                                                      
            M_PROP_VALUE := 5;                                                                                                                                  
        END CASE;                                                                                                                                               
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS THEN                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
         UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                           
         SET NUMBER_VALUE = M_PROP_VALUE                                                                                                                        
         WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                  
               AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS;                                                                                                          
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES OR                                                                                                                
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML THEN                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
         UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                           
         SET NUMBER_VALUE = M_PROP_VALUE                                                                                                                        
         WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                  
               AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML;                                                                                                         
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
    ELSIF AUDIT_TRAIL_PROPERTY = DB_DELETE_BATCH_SIZE                                                                                                           
    THEN                                                                                                                                                        
                                                                                                                                                                
      IF USE_DEFAULT_VALUES = FALSE THEN                                                                                                                        
        M_PROP_VALUE := 0;                                                                                                                                      
      ELSE                                                                                                                                                      
        M_PROP_VALUE := 10000;                                                                                                                                  
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD THEN                                                                                                            
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = M_PROP_VALUE                                                                                                                         
        WHERE PARAM_ID = DB_DELETE_BATCH_SIZE                                                                                                                   
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD;                                                                                                      
                                                                                                                                                                
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD THEN                                                                                                         
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = M_PROP_VALUE                                                                                                                         
        WHERE PARAM_ID = DB_DELETE_BATCH_SIZE                                                                                                                   
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD;                                                                                                      
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
    ELSIF AUDIT_TRAIL_PROPERTY = FILE_DELETE_BATCH_SIZE                                                                                                         
    THEN                                                                                                                                                        
                                                                                                                                                                
      IF USE_DEFAULT_VALUES = FALSE THEN                                                                                                                        
        M_PROP_VALUE := 0;                                                                                                                                      
      ELSE                                                                                                                                                      
        M_PROP_VALUE := 10000;                                                                                                                                  
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS THEN                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = M_PROP_VALUE                                                                                                                         
        WHERE PARAM_ID = FILE_DELETE_BATCH_SIZE                                                                                                                 
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS;                                                                                                           
                                                                                                                                                                
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML THEN                                                                                                             
                                                                                                                                                                
                                                                                                                                                                
        UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                            
        SET NUMBER_VALUE = M_PROP_VALUE                                                                                                                         
        WHERE PARAM_ID = FILE_DELETE_BATCH_SIZE                                                                                                                 
              AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML;                                                                                                          
                                                                                                                                                                
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE OR                                                                                                                
       AUDIT_TRAIL_PROPERTY = DB_DELETE_BATCH_SIZE OR                                                                                                           
       AUDIT_TRAIL_PROPERTY = FILE_DELETE_BATCH_SIZE OR                                                                                                         
       AUDIT_TRAIL_PROPERTY = AUD_TAB_MOVEMENT_FLAG                                                                                                             
    THEN                                                                                                                                                        
      UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY);                                                                                           
    END IF;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAN_AUDIT_TRAIL_11G                                                                                                                               
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE                                                                                                      
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_SETUP_COUNT    NUMBER;                                                                                                                                    
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In clean_audit_trail_11g');                                                                                        
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE > AUDIT_TRAIL_ALL THEN                                                                                                                  
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                                 
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD                                                                                                             
            AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                   
                                                                                                                                                                
      IF M_SETUP_COUNT <= 0                                                                                                                                     
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                                 
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD                                                                                                             
            AND PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                   
                                                                                                                                                                
      IF M_SETUP_COUNT <= 0                                                                                                                                     
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                     
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                    
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                     
    THEN                                                                                                                                                        
      IF M_FIL_LCK_HDL IS NULL THEN                                                                                                                             
        DBMS_LOCK.ALLOCATE_UNIQUE(FIL_CLEAN, M_FIL_LCK_HDL);                                                                                                    
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF DBMS_LOCK.REQUEST(M_FIL_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                     
                           0 ) <> 0 THEN                                                                                                                        
        RAISE_ORA_ERROR(46269);                                                                                                                                 
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      CLEAN_AUDIT_TRAIL_INT(AUDIT_TRAIL_TYPE, USE_LAST_ARCH_TIMESTAMP);                                                                                         
                                                                                                                                                                
      IF DBMS_LOCK.RELEASE(M_FIL_LCK_HDL) <> 0 THEN                                                                                                             
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_FIL_LCK_HDL := NULL;                                                                                                                                    
                                                                                                                                                                
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        IF DBMS_LOCK.RELEASE(M_FIL_LCK_HDL) <> 0 THEN                                                                                                           
          NULL;                                                                                                                                                 
        END IF;                                                                                                                                                 
        M_FIL_LCK_HDL := NULL;                                                                                                                                  
                                                                                                                                                                
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CREATE_PURGE_JOB_11G                                                                                                                                
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_INTERVAL IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2,                                                                                                            
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE,                                                                                                     
             CONTAINER                  IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_INTERVAL         VARCHAR2(200);                                                                                                                           
    M_SQL_STMT         VARCHAR2(1000);                                                                                                                          
    M_JOBS             NUMBER := 0;                                                                                                                             
    M_TRAIL_COUNT      NUMBER := 0;                                                                                                                             
    M_SETUP_COUNT      NUMBER := 0;                                                                                                                             
    M_ATRAIL_TYPE      NUMBER := AUDIT_TRAIL_TYPE;                                                                                                              
    M_NEW_JOB_NAME     VARCHAR2(100);                                                                                                                           
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'In create_purge_job_11g');                                                                                          
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE > AUDIT_TRAIL_ALL THEN                                                                                                                  
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PURGE_NAME IS NULL OR                                                                                                                        
       LENGTH(AUDIT_TRAIL_PURGE_NAME) = 0 OR                                                                                                                    
       LENGTH(AUDIT_TRAIL_PURGE_NAME) > 100                                                                                                                     
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_NEW_JOB_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(AUDIT_TRAIL_PURGE_NAME);                                                                                    
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                       
    END;                                                                                                                                                        
                                                                                                                                                                
    IF AUDIT_TRAIL_PURGE_INTERVAL <= 0 OR                                                                                                                       
       AUDIT_TRAIL_PURGE_INTERVAL >= 1000                                                                                                                       
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_PURGE_INTERVAL');                                                                                                     
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    SELECT COUNT(JOB_NAME) INTO M_JOBS FROM SYS.DAM_CLEANUP_JOBS$                                                                                               
    WHERE JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                                 
                                                                                                                                                                
    IF M_JOBS >= 1 THEN                                                                                                                                         
      RAISE_ORA_ERROR(46254, M_NEW_JOB_NAME);                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                   
    FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                  
    WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_ALL;                                                                                                                  
                                                                                                                                                                
    IF M_TRAIL_COUNT >= 1 THEN                                                                                                                                  
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                    
                          'Job for AUDIT_TRAIL_ALL present ');                                                                                                  
      RAISE_ORA_ERROR(46252);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_TRAIL_COUNT := 0;                                                                                                                                         
                                                                                                                                                                
    CASE AUDIT_TRAIL_TYPE                                                                                                                                       
                                                                                                                                                                
    WHEN  AUDIT_TRAIL_AUD_STD                                                                                                                                   
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                 
      FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD OR                                                                                                          
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_DB_STD;                                                                                                             
                                                                                                                                                                
    WHEN AUDIT_TRAIL_FGA_STD                                                                                                                                    
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                 
      FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD OR                                                                                                          
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_DB_STD;                                                                                                             
                                                                                                                                                                
    WHEN AUDIT_TRAIL_OS                                                                                                                                         
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                 
      FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS OR                                                                                                               
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FILES;                                                                                                              
                                                                                                                                                                
    WHEN AUDIT_TRAIL_XML                                                                                                                                        
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                 
      FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML OR                                                                                                              
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FILES;                                                                                                              
                                                                                                                                                                
    WHEN AUDIT_TRAIL_DB_STD                                                                                                                                     
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                 
      FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD OR                                                                                                          
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD OR                                                                                                          
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_DB_STD;                                                                                                             
                                                                                                                                                                
    WHEN AUDIT_TRAIL_FILES                                                                                                                                      
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                 
      FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS OR                                                                                                               
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML OR                                                                                                              
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FILES;                                                                                                              
                                                                                                                                                                
    WHEN AUDIT_TRAIL_ALL                                                                                                                                        
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(JOB_NAME) INTO M_TRAIL_COUNT                                                                                                                 
      FROM SYS.DAM_CLEANUP_JOBS$                                                                                                                                
      WHERE AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS OR                                                                                                               
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML OR                                                                                                              
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD OR                                                                                                          
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD OR                                                                                                          
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_DB_STD OR                                                                                                           
            AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FILES;                                                                                                              
                                                                                                                                                                
    END CASE;                                                                                                                                                   
                                                                                                                                                                
    IF M_TRAIL_COUNT >= 1 THEN                                                                                                                                  
      RAISE_ORA_ERROR(46252);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL;                                                                                                                       
                                                                                                                                                                
      IF M_SETUP_COUNT != 4                                                                                                                                     
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD                                                                                                                 
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD                                                                                                            
             OR AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD);                                                                                                       
                                                                                                                                                                
      IF M_SETUP_COUNT != 2                                                                                                                                     
      THEN                                                                                                                                                      
        RAISE_ORA_ERROR(46258);                                                                                                                                 
      END IF;                                                                                                                                                   
    ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES                                                                                                                  
    THEN                                                                                                                                                        
      SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                                 
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                    
            (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_OS                                                                                                                 
             OR AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_XML);                                                                                                           
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    ELSE                                                                                                                                                        
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD OR                                                                                                              
         AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD                                                                                                                 
      THEN                                                                                                                                                      
        SELECT COUNT(PARAM_ID) INTO M_SETUP_COUNT                                                                                                               
        FROM SYS.DAM_CONFIG_PARAM$                                                                                                                              
        WHERE PARAM_ID = CLEAN_UP_INTERVAL AND                                                                                                                  
              AUDIT_TRAIL_TYPE# = M_ATRAIL_TYPE;                                                                                                                
                                                                                                                                                                
        IF M_SETUP_COUNT <= 0                                                                                                                                   
        THEN                                                                                                                                                    
          RAISE_ORA_ERROR(46258);                                                                                                                               
        END IF;                                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF USE_LAST_ARCH_TIMESTAMP = TRUE THEN                                                                                                                      
      M_SQL_STMT := 'BEGIN ' ||                                                                                                                                 
                    'DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL('||                                                                                                      
                    M_ATRAIL_TYPE || ', ' ||                                                                                                                    
                    'TRUE' || ', ' || CONTAINER || '); '                                                                                                        
                    || ' END;';                                                                                                                                 
    ELSE                                                                                                                                                        
      M_SQL_STMT := 'BEGIN ' ||                                                                                                                                 
                    'DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL('||                                                                                                      
                    M_ATRAIL_TYPE || ', ' ||                                                                                                                    
                    'FALSE' || ', ' || CONTAINER || '); '                                                                                                       
                    || ' END;';                                                                                                                                 
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_INTERVAL := 'FREQ=HOURLY;INTERVAL=';                                                                                                                      
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      DBMS_SCHEDULER.CREATE_JOB (                                                                                                                               
        JOB_NAME           =>  M_NEW_JOB_NAME,                                                                                                                  
        JOB_TYPE           =>  'PLSQL_BLOCK',                                                                                                                   
        JOB_ACTION         =>  M_SQL_STMT,                                                                                                                      
        REPEAT_INTERVAL    =>  M_INTERVAL || AUDIT_TRAIL_PURGE_INTERVAL,                                                                                        
        COMMENTS           =>  'Audit clean job = ''' ||                                                                                                        
                                M_NEW_JOB_NAME || '''');                                                                                                        
    END;                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      DBMS_SCHEDULER.ENABLE(M_NEW_JOB_NAME);                                                                                                                    
    END;                                                                                                                                                        
                                                                                                                                                                
    INSERT INTO SYS.DAM_CLEANUP_JOBS$ VALUES                                                                                                                    
    (NLS_UPPER(M_NEW_JOB_NAME), 1 , M_ATRAIL_TYPE,                                                                                                              
     AUDIT_TRAIL_PURGE_INTERVAL, M_INTERVAL||AUDIT_TRAIL_PURGE_INTERVAL);                                                                                       
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE MOVE_TABLESPACES                                                                                                                                    
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_LOCATION_VALUE IN VARCHAR2,                                                                                                            
             AUDIT_PART_CNT             IN NUMBER                                                                                                               
            )                                                                                                                                                   
  IS                                                                                                                                                            
    CURSOR SEL_DBA_PAR (TAB_OWNER VARCHAR2, TAB_NAME VARCHAR2) IS                                                                                               
      SELECT PARTITION_POSITION, PARTITION_NAME, TABLESPACE_NAME                                                                                                
      FROM DBA_TAB_PARTITIONS                                                                                                                                   
      WHERE TABLE_NAME = TAB_NAME AND                                                                                                                           
            TABLE_OWNER = TAB_OWNER                                                                                                                             
      ORDER BY PARTITION_POSITION;                                                                                                                              
                                                                                                                                                                
    M_TABLE_NAME    VARCHAR2(10);                                                                                                                               
    M_ALTER_CMD     VARCHAR2(4000);                                                                                                                             
    M_ATRAIL_TYPE   NUMBER := AUDIT_TRAIL_TYPE;                                                                                                                 
    M_REC_CNT       NUMBER;                                                                                                                                     
    M_TBSCHEMA_TMP  VARCHAR2(32);                                                                                                                               
    M_TBSCHEMA      VARCHAR2(32);                                                                                                                               
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In move_tablespaces ');                                                                                            
                                                                                                                                                                
    IF AUDIT_PART_CNT <= 0                                                                                                                                      
    THEN                                                                                                                                                        
       IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD                                                                                                                
       THEN                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
         MOVE_STD_AUD_TABLESPACE(AUDIT_TRAIL_LOCATION_VALUE);                                                                                                   
                                                                                                                                                                
       ELSIF  AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD                                                                                                            
       THEN                                                                                                                                                     
         MOVE_FGA_TABLESPACE(AUDIT_TRAIL_LOCATION_VALUE);                                                                                                       
       END IF;                                                                                                                                                  
    ELSE                                                                                                                                                        
      IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_AUD_STD THEN                                                                                                            
         M_TABLE_NAME := 'AUD$';                                                                                                                                
                                                                                                                                                                
         SELECT U.USERNAME INTO M_TBSCHEMA_TMP FROM OBJ$ O, DBA_USERS U                                                                                         
         WHERE O.NAME = 'AUD$' AND O.TYPE#=2 AND O.OWNER# = U.USER_ID                                                                                           
               AND O.REMOTEOWNER IS NULL AND O.LINKNAME IS NULL                                                                                                 
               AND U.USERNAME = 'SYS';                                                                                                                          
         M_TBSCHEMA := DBMS_ASSERT.ENQUOTE_NAME(M_TBSCHEMA_TMP, FALSE);                                                                                         
                                                                                                                                                                
      ELSIF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FGA_STD THEN                                                                                                         
         M_TABLE_NAME := 'FGA_LOG$';                                                                                                                            
         M_TBSCHEMA := 'SYS';                                                                                                                                   
      END IF;                                                                                                                                                   
                                                                                                                                                                
      FOR PART_INFO IN SEL_DBA_PAR(M_TBSCHEMA, M_TABLE_NAME) LOOP                                                                                               
          M_ALTER_CMD := 'ALTER TABLE ' || M_TBSCHEMA || '.' || M_TABLE_NAME ||                                                                                 
                         ' MOVE PARTITION ' ||                                                                                                                  
                         DBMS_ASSERT.SIMPLE_SQL_NAME(PART_INFO.PARTITION_NAME)                                                                                  
                         || ' TABLESPACE ' || AUDIT_TRAIL_LOCATION_VALUE ||                                                                                     
                         ' LOB(SQLBIND, SQLTEXT) STORE AS (TABLESPACE '||                                                                                       
                         AUDIT_TRAIL_LOCATION_VALUE || ')';                                                                                                     
                                                                                                                                                                
          DBMS_PDB_EXEC_SQL(M_ALTER_CMD);                                                                                                                       
      END LOOP;                                                                                                                                                 
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                          
    USING (SELECT COUNT(*) R_CNT                                                                                                                                
         FROM SYS.DAM_CONFIG_PARAM$                                                                                                                             
         WHERE PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                   
               AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE) S                                                                                                      
                ON (S.R_CNT = 1)                                                                                                                                
    WHEN MATCHED THEN                                                                                                                                           
         UPDATE SET D.STRING_VALUE = AUDIT_TRAIL_LOCATION_VALUE                                                                                                 
         WHERE D.PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                 
           AND D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE                                                                                                           
    WHEN NOT MATCHED THEN                                                                                                                                       
         INSERT VALUES(DB_AUDIT_TABLEPSACE, AUDIT_TRAIL_TYPE, NULL,                                                                                             
                   AUDIT_TRAIL_LOCATION_VALUE);                                                                                                                 
                                                                                                                                                                
    UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_TYPE, DB_AUDIT_TABLEPSACE);                                                                                              
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE MOVE_FGA_TABLESPACE(TBS_NAME IN VARCHAR2)                                                                                                           
  IS                                                                                                                                                            
    M_TMP_SQL     VARCHAR2(4000);                                                                                                                               
    M_FGA_COLS    VARCHAR2(1000);                                                                                                                               
    M_FGA_COLS2   VARCHAR2(1000);                                                                                                                               
    M_MAX_TSTMP   TIMESTAMP;                                                                                                                                    
    M_TBS_NAME    VARCHAR2(32);                                                                                                                                 
  BEGIN                                                                                                                                                         
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'In move_fga_tablespace');                                                                                         
                                                                                                                                                                
      IF TBS_NAME IS NULL OR                                                                                                                                    
         LENGTH(TBS_NAME) = 0 OR                                                                                                                                
         LENGTH(TBS_NAME) > 30                                                                                                                                  
      THEN                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: TBS_NAME');                                                                                          
        RAISE_ORA_ERROR(46250, 'TBS_NAME');                                                                                                                     
      END IF;                                                                                                                                                   
                                                                                                                                                                
      BEGIN                                                                                                                                                     
        M_TBS_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(TBS_NAME);                                                                                                    
      EXCEPTION                                                                                                                                                 
        WHEN OTHERS THEN                                                                                                                                        
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: SQL_NAME');                                                                                        
          RAISE_ORA_ERROR(46250, 'TBS_NAME');                                                                                                                   
      END;                                                                                                                                                      
                                                                                                                                                                
      BEGIN                                                                                                                                                     
        M_TMP_SQL := 'create table sys.dam_temp_fga_log$(' ||                                                                                                   
        'sessionid number not null, timestamp# date, dbuid varchar2(30), ' ||                                                                                   
        'osuid varchar2(255), oshst varchar2(128), clientid varchar2(64), ' ||                                                                                  
        'extid varchar2(4000), obj$schema varchar2(30), ' ||                                                                                                    
        'obj$name varchar2(128), policyname varchar2(30), scn number, ' ||                                                                                      
        'sqltext varchar2(4000), lsqltext clob, sqlbind varchar2(4000), ' ||                                                                                    
        'comment$text varchar2(4000), plhol long, stmt_type number, ' ||                                                                                        
        'ntimestamp# timestamp, proxy$sid number, user$guid varchar2(32), ' ||                                                                                  
        'instance# number, process# varchar2(16), xid raw(8), ' ||                                                                                              
        'auditid varchar2(64), statement number, entryid number, ' ||                                                                                           
        'dbid number, lsqlbind clob, obj$edition varchar2(30)) tablespace ' ||                                                                                  
        M_TBS_NAME;                                                                                                                                             
                                                                                                                                                                
        DBMS_PDB_EXEC_SQL(M_TMP_SQL);                                                                                                                           
        EXECUTE IMMEDIATE 'SELECT MAX(NTIMESTAMP#) FROM SYS.FGA_LOG$'                                                                                           
        INTO M_MAX_TSTMP;                                                                                                                                       
                                                                                                                                                                
        M_FGA_COLS := 'sessionid, timestamp#, dbuid, osuid, oshst, ' ||                                                                                         
                      'clientid, extid, obj$schema, obj$name, policyname, '||                                                                                   
                      'scn, sqltext, lsqltext, sqlbind, comment$text, ' ||                                                                                      
                      'plhol , stmt_type, ntimestamp#, proxy$sid, ' ||                                                                                          
                      'user$guid, instance#, process#, xid, auditid, ' ||                                                                                       
                      'statement, entryid, dbid, lsqlbind, obj$edition';                                                                                        
                                                                                                                                                                
                                                                                                                                                                
        M_FGA_COLS2 := 'sessionid, timestamp#, dbuid, osuid, oshst, ' ||                                                                                        
                       'clientid, extid, obj$schema, obj$name, policyname, '||                                                                                  
                       'scn, sqltext, lsqltext, sqlbind, comment$text, ' ||                                                                                     
                       'null , stmt_type, ntimestamp#, proxy$sid, ' ||                                                                                          
                       'user$guid, instance#, process#, xid, auditid, ' ||                                                                                      
                       'statement, entryid, dbid, lsqlbind, obj$edition';                                                                                       
                                                                                                                                                                
        IF M_MAX_TSTMP IS NOT NULL THEN                                                                                                                         
          EXECUTE IMMEDIATE 'insert into sys.dam_temp_fga_log$(' ||                                                                                             
                            M_FGA_COLS || ') select ' || M_FGA_COLS2 ||                                                                                         
                            ' from sys.fga_log$ where ntimestamp# <= ''' ||                                                                                     
                            M_MAX_TSTMP || '''';                                                                                                                
        END IF;                                                                                                                                                 
                                                                                                                                                                
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Phase 1 complete');                                                                                             
                                                                                                                                                                
      EXCEPTION                                                                                                                                                 
        WHEN OTHERS THEN                                                                                                                                        
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'Phase 1 error');                                                                                              
          DBMS_PDB_EXEC_SQL('DROP TABLE SYS.dam_temp_fga_log$');                                                                                                
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46264');                                                                                                  
          RAISE_ORA_ERROR(46264);                                                                                                                               
      END;                                                                                                                                                      
                                                                                                                                                                
                                                                                                                                                                
      IF ENQUEUE_GET_REL(AUDIT_TRAIL_FGA_STD, 1 ) = 1 THEN                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                  
                            'FGA_LOG$: Enqueue Acquire error, ORA-46264');                                                                                      
        RAISE_ORA_ERROR(46264);                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
      DBMS_LOCK.SLEEP(3);                                                                                                                                       
      BEGIN                                                                                                                                                     
        IF M_MAX_TSTMP IS NOT NULL THEN                                                                                                                         
          EXECUTE IMMEDIATE 'insert into sys.dam_temp_fga_log$(' ||                                                                                             
                            M_FGA_COLS || ') select ' || M_FGA_COLS2 ||                                                                                         
                            ' from sys.fga_log$ where ntimestamp# > ''' ||                                                                                      
                            M_MAX_TSTMP || '''';                                                                                                                
        ELSE                                                                                                                                                    
          EXECUTE IMMEDIATE 'insert into sys.dam_temp_fga_log$(' ||                                                                                             
                            M_FGA_COLS || ') select ' || M_FGA_COLS2 ||                                                                                         
                            ' from sys.fga_log$';                                                                                                               
        END IF;                                                                                                                                                 
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Phase 2 complete');                                                                                             
      EXCEPTION                                                                                                                                                 
        WHEN OTHERS THEN                                                                                                                                        
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'Phase 2 error');                                                                                              
          EXECUTE IMMEDIATE 'DROP TABLE SYS.dam_temp_fga_log$';                                                                                                 
          COMMIT;                                                                                                                                               
          WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46264');                                                                                                  
          RAISE_ORA_ERROR(46264);                                                                                                                               
      END;                                                                                                                                                      
                                                                                                                                                                
      DBMS_PDB_EXEC_SQL('DROP TABLE SYS.FGA_LOG$');                                                                                                             
      DBMS_PDB_EXEC_SQL('ALTER TABLE SYS.dam_temp_fga_log$ ' ||                                                                                                 
                        'RENAME TO FGA_LOG$');                                                                                                                  
                                                                                                                                                                
      IF ENQUEUE_GET_REL(AUDIT_TRAIL_FGA_STD, 2 ) = 1 THEN                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                  
                            'FGA_LOG$: Enqueue Release error, ORA-46264');                                                                                      
        RAISE_ORA_ERROR(46264);                                                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
      COMMIT;                                                                                                                                                   
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
  FUNCTION IS_CLEANUP_INITIALIZED_11G                                                                                                                           
           (AUDIT_TRAIL_TYPE           IN PLS_INTEGER)                                                                                                          
  RETURN BOOLEAN                                                                                                                                                
  IS                                                                                                                                                            
    M_ATRAIL_CNT    NUMBER;                                                                                                                                     
    M_ATRAIL_TYP    NUMBER := AUDIT_TRAIL_TYPE;                                                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'In is_cleanup_initialized_11g');                                                                                    
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE < AUDIT_TRAIL_AUD_STD OR                                                                                                                
       AUDIT_TRAIL_TYPE > AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_OS OR                                                                                                                     
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_XML OR                                                                                                                    
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_FILES THEN                                                                                                                
      RETURN TRUE;                                                                                                                                              
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE = AUDIT_TRAIL_DB_STD OR                                                                                                                 
       AUDIT_TRAIL_TYPE = AUDIT_TRAIL_ALL                                                                                                                       
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(AUDIT_TRAIL_TYPE#) INTO M_ATRAIL_CNT                                                                                                         
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                        
          AND (AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_AUD_STD OR                                                                                                       
               AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_FGA_STD);                                                                                                        
                                                                                                                                                                
      IF M_ATRAIL_CNT = 2 THEN                                                                                                                                  
        RETURN TRUE;                                                                                                                                            
      ELSE                                                                                                                                                      
        RETURN FALSE;                                                                                                                                           
      END IF;                                                                                                                                                   
    ELSE                                                                                                                                                        
                                                                                                                                                                
      SELECT COUNT(AUDIT_TRAIL_TYPE#) INTO M_ATRAIL_CNT                                                                                                         
      FROM SYS.DAM_CONFIG_PARAM$                                                                                                                                
      WHERE PARAM_ID = CLEAN_UP_INTERVAL                                                                                                                        
          AND AUDIT_TRAIL_TYPE# = M_ATRAIL_TYP;                                                                                                                 
                                                                                                                                                                
      IF M_ATRAIL_CNT = 1 THEN                                                                                                                                  
        RETURN TRUE;                                                                                                                                            
      ELSE                                                                                                                                                      
        RETURN FALSE;                                                                                                                                           
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE MODIFY_AUDIT_TRAIL                                                                                                                                  
            (TBSCHEMA                   IN VARCHAR2,                                                                                                            
             TABLENAME                  IN VARCHAR2,                                                                                                            
             TBSPACE                    IN VARCHAR2,                                                                                                            
             ACTION                     IN PLS_INTEGER,                                                                                                         
             DEFAULT_CLEANUP_INTERVAL   IN PLS_INTEGER := 0                                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_TEMP_STMT      VARCHAR2(1000);                                                                                                                            
    M_FGA_STMT       VARCHAR2(1000);                                                                                                                            
    IS_PART_NALL     BOOLEAN := PART_DISALLOWED();                                                                                                              
    M_OLS_INST       VARCHAR2(10);                                                                                                                              
    M_MAX_TSTMP      TIMESTAMP;                                                                                                                                 
    M_TSTAMP_MAXV    TIMESTAMP;                                                                                                                                 
    M_PARTITION_NAME VARCHAR2(9);                                                                                                                               
    AUDIT_TRAIL_TYPE PLS_INTEGER;                                                                                                                               
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    L_TBSCHEMA       VARCHAR2(32) := DBMS_ASSERT.ENQUOTE_NAME(TBSCHEMA, FALSE);                                                                                 
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,' In modify_audit_trail');                                                                                            
    IF TABLENAME = 'AUD$'                                                                                                                                       
    THEN                                                                                                                                                        
       M_PARTITION_NAME := 'aud_p001';                                                                                                                          
       AUDIT_TRAIL_TYPE := AUDIT_TRAIL_AUD_STD;                                                                                                                 
    ELSE                                                                                                                                                        
       M_PARTITION_NAME := 'fga_p001';                                                                                                                          
       AUDIT_TRAIL_TYPE := AUDIT_TRAIL_FGA_STD;                                                                                                                 
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
      IF ACTION = PARTITION                                                                                                                                     
      THEN                                                                                                                                                      
        IF IS_PART_NALL = TRUE THEN                                                                                                                             
          EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''14524 TRACE NAME                                                                                        
          CONTEXT FOREVER, LEVEL 1''';                                                                                                                          
        END IF;                                                                                                                                                 
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
	                                                                                                                                                               
        IF TABLENAME ='AUD$'                                                                                                                                    
        THEN                                                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
          MOVE_STD_AUD_TABLESPACE(TBSPACE);                                                                                                                     
                                                                                                                                                                
        ELSE                                                                                                                                                    
          MOVE_FGA_TABLESPACE(TBSPACE);                                                                                                                         
        END IF ;                                                                                                                                                
                                                                                                                                                                
      ELSIF ACTION = UNPARTITION                                                                                                                                
      THEN                                                                                                                                                      
        NULL;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      ELSE                                                                                                                                                      
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,' Invalid action');                                                                                               
      END IF;                                                                                                                                                   
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
 END;                                                                                                                                                           
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION PART_DISALLOWED                                                                                                                                      
  RETURN   BOOLEAN                                                                                                                                              
  IS                                                                                                                                                            
    OBANNER    VARCHAR2(200);                                                                                                                                   
    SPOSITION  NUMBER;                                                                                                                                          
  BEGIN                                                                                                                                                         
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      SELECT BANNER INTO OBANNER FROM V$VERSION WHERE BANNER LIKE 'Personal%';                                                                                  
      RETURN TRUE;                                                                                                                                              
    EXCEPTION                                                                                                                                                   
      WHEN NO_DATA_FOUND THEN                                                                                                                                   
        NULL;                                                                                                                                                   
                                                                                                                                                                
    END;                                                                                                                                                        
                                                                                                                                                                
    SELECT BANNER INTO OBANNER FROM V$VERSION WHERE BANNER LIKE 'Oracle%';                                                                                      
    SELECT INSTR(OBANNER, 'Enterprise', 1, 1) INTO SPOSITION FROM DUAL;                                                                                         
                                                                                                                                                                
    IF SPOSITION = 0 THEN                                                                                                                                       
      RETURN TRUE;                                                                                                                                              
    ELSE                                                                                                                                                        
      RETURN FALSE;                                                                                                                                             
    END IF;                                                                                                                                                     
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CHNG_OLS_AUD_TAB                                                                                                                                    
           (TSTAMP_PART_MAXV          IN  TIMESTAMP,                                                                                                            
            TBSPACE_DEST              IN  VARCHAR2                                                                                                              
           )                                                                                                                                                    
  IS                                                                                                                                                            
    M_SQL_STMT       VARCHAR2(4000);                                                                                                                            
    M_COL_LST        VARCHAR2(2048);                                                                                                                            
    M_MAX_TSTMP      TIMESTAMP;                                                                                                                                 
    M_COUNT          NUMBER;                                                                                                                                    
    M_TOTAL          NUMBER;                                                                                                                                    
    M_TBS_NAME       VARCHAR2(32);                                                                                                                              
    TYPE VARCHARARR IS VARRAY(100) OF VARCHAR2(32);                                                                                                             
    TYPE NUMBERARR IS VARRAY(100) OF NUMBER;                                                                                                                    
    M_COL_NAME  VARCHARARR := VARCHARARR();                                                                                                                     
    M_COL_DTYPE VARCHARARR := VARCHARARR();                                                                                                                     
    M_HIDDEN    NUMBERARR := NUMBERARR();                                                                                                                       
    CURSOR SEL_HIDDEN_COLS IS                                                                                                                                   
      SELECT COLUMN_NAME, DATA_TYPE, HIDDEN_COLUMN                                                                                                              
      FROM ALL_TAB_COLS                                                                                                                                         
      WHERE TABLE_NAME = 'AUD$' ORDER BY COLUMN_ID ASC;                                                                                                         
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In chng_ols_aud_tab');                                                                                             
                                                                                                                                                                
    IF TBSPACE_DEST IS NULL OR                                                                                                                                  
       LENGTH(TBSPACE_DEST) = 0 OR                                                                                                                              
       LENGTH(TBSPACE_DEST) > 30                                                                                                                                
    THEN                                                                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: TBSPACE_DEST');                                                                                        
      RAISE_ORA_ERROR(46250, 'TBSPACE_DEST');                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_TBS_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(TBSPACE_DEST);                                                                                                  
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: TBSPACE_DEST');                                                                                      
        RAISE_ORA_ERROR(46250, 'TBSPACE_DEST');                                                                                                                 
    END;                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      IF TSTAMP_PART_MAXV IS NOT NULL THEN                                                                                                                      
        M_SQL_STMT := 'CREATE TABLE SYSTEM.dam_temp_aud$ ' ||                                                                                                   
                      'PARTITION BY range(ntimestamp#)' ||                                                                                                      
                      '(PARTITION aud_p001 values less than( ''' ||                                                                                             
                      TSTAMP_PART_MAXV || ''')) ' ||                                                                                                            
                      'TABLESPACE ' || M_TBS_NAME || ' NOLOGGING ' ||                                                                                           
                      '  AS select * from SYSTEM.aud$ where action# = 0 ';                                                                                      
      ELSE                                                                                                                                                      
        M_SQL_STMT := 'CREATE TABLE SYSTEM.dam_temp_aud$ ' ||                                                                                                   
                      'TABLESPACE ' || M_TBS_NAME || ' NOLOGGING ' ||                                                                                           
                      '  AS select * from SYSTEM.aud$ where action# = 0 ';                                                                                      
      END IF;                                                                                                                                                   
                                                                                                                                                                
      EXECUTE IMMEDIATE M_SQL_STMT;                                                                                                                             
                                                                                                                                                                
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Phase 1 complete');                                                                                               
                                                                                                                                                                
                                                                                                                                                                
      M_COUNT := 1;                                                                                                                                             
      FOR  COL_INFO IN SEL_HIDDEN_COLS LOOP                                                                                                                     
        IF M_COUNT < M_COL_NAME.LIMIT THEN                                                                                                                      
          M_COL_NAME.EXTEND;                                                                                                                                    
          M_COL_DTYPE.EXTEND;                                                                                                                                   
          M_HIDDEN.EXTEND;                                                                                                                                      
                                                                                                                                                                
          M_COL_NAME(M_COL_NAME.LAST) := COL_INFO.COLUMN_NAME;                                                                                                  
          M_COL_DTYPE(M_COL_DTYPE.LAST) := COL_INFO.DATA_TYPE;                                                                                                  
          IF COL_INFO.HIDDEN_COLUMN = 'NO' THEN                                                                                                                 
            M_HIDDEN(M_HIDDEN.LAST) := 0;                                                                                                                       
          ELSE                                                                                                                                                  
            ADD_HIDDEN_COLUMNS('DAM_TEMP_AUD$',                                                                                                                 
                               COL_INFO.COLUMN_NAME, COL_INFO.DATA_TYPE);                                                                                       
            M_HIDDEN(M_HIDDEN.LAST) := 1;                                                                                                                       
          END IF;                                                                                                                                               
          M_COUNT := M_COUNT + 1;                                                                                                                               
        END IF;                                                                                                                                                 
      END LOOP;                                                                                                                                                 
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'Phase 2 error# 1');                                                                                             
        EXECUTE IMMEDIATE 'DROP TABLE SYSTEM.dam_temp_aud$';                                                                                                    
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
    M_TOTAL := M_COUNT-1;                                                                                                                                       
                                                                                                                                                                
    M_COL_LST := ' ';                                                                                                                                           
    FOR M_COUNT IN 1..M_TOTAL-1 LOOP                                                                                                                            
      M_COL_LST := M_COL_LST || ' ' || M_COL_NAME(M_COUNT) || ',';                                                                                              
    END LOOP;                                                                                                                                                   
                                                                                                                                                                
    M_COL_LST := M_COL_LST || ' ' || M_COL_NAME(M_TOTAL);                                                                                                       
                                                                                                                                                                
    M_SQL_STMT := 'SELECT MAX(NTIMESTAMP#) FROM SYSTEM.AUD$';                                                                                                   
    EXECUTE IMMEDIATE M_SQL_STMT INTO M_MAX_TSTMP;                                                                                                              
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      IF M_MAX_TSTMP IS NOT NULL THEN                                                                                                                           
        M_SQL_STMT := 'INSERT INTO SYSTEM.dam_temp_aud$ (' ||                                                                                                   
                      M_COL_LST || ')' ||                                                                                                                       
                      ' SELECT ' || M_COL_LST || ' FROM SYSTEM.aud$' ||                                                                                         
                      ' WHERE  NTIMESTAMP# <= ''' || M_MAX_TSTMP || '''';                                                                                       
      ELSE                                                                                                                                                      
        M_SQL_STMT := 'INSERT INTO SYSTEM.dam_temp_aud$ (' ||                                                                                                   
                      M_COL_LST || ')' ||                                                                                                                       
                      ' SELECT ' || M_COL_LST || ' FROM SYSTEM.aud$';                                                                                           
      END IF;                                                                                                                                                   
                                                                                                                                                                
      EXECUTE IMMEDIATE M_SQL_STMT;                                                                                                                             
                                                                                                                                                                
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Phase 2 complete');                                                                                               
                                                                                                                                                                
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'Phase 2 error# 2');                                                                                             
        EXECUTE IMMEDIATE 'DROP TABLE SYSTEM.dam_temp_aud$';                                                                                                    
                                                                                                                                                                
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46264');                                                                                                    
        RAISE_ORA_ERROR(46264);                                                                                                                                 
    END;                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    IF ENQUEUE_GET_REL(AUDIT_TRAIL_AUD_STD, 1 ) = 1 THEN                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                    
                          'SYSTEM.AUD$: Enqueue Acquire error, ORA-46264');                                                                                     
      RAISE_ORA_ERROR(46264);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    DBMS_LOCK.SLEEP(3);                                                                                                                                         
    BEGIN                                                                                                                                                       
      IF M_MAX_TSTMP IS NOT NULL THEN                                                                                                                           
        M_SQL_STMT := 'INSERT INTO SYSTEM.dam_temp_aud$ (' ||                                                                                                   
                      M_COL_LST || ')' ||                                                                                                                       
                      ' SELECT ' || M_COL_LST || ' FROM SYSTEM.aud$' ||                                                                                         
                      ' WHERE  NTIMESTAMP# > ''' || M_MAX_TSTMP || '''';                                                                                        
      ELSE                                                                                                                                                      
        M_SQL_STMT := 'INSERT INTO SYSTEM.dam_temp_aud$ (' ||                                                                                                   
                      M_COL_LST || ')' ||                                                                                                                       
                      ' SELECT ' || M_COL_LST || ' FROM SYSTEM.aud$';                                                                                           
      END IF;                                                                                                                                                   
                                                                                                                                                                
      EXECUTE IMMEDIATE M_SQL_STMT;                                                                                                                             
                                                                                                                                                                
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Phase 3 complete');                                                                                               
                                                                                                                                                                
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'Phase 3 error# 1');                                                                                             
        EXECUTE IMMEDIATE 'DROP TABLE SYSTEM.dam_temp_aud$';                                                                                                    
        COMMIT;                                                                                                                                                 
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46264');                                                                                                    
        RAISE_ORA_ERROR(46264);                                                                                                                                 
    END;                                                                                                                                                        
                                                                                                                                                                
    EXECUTE IMMEDIATE 'DROP TABLE SYSTEM.AUD$';                                                                                                                 
    EXECUTE IMMEDIATE 'ALTER TABLE SYSTEM.dam_temp_aud$ RENAME TO AUD$';                                                                                        
    EXECUTE IMMEDIATE 'ALTER TABLE SYSTEM.AUD$ LOGGING';                                                                                                        
                                                                                                                                                                
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM aud$ FOR SYSTEM.aud$';                                                                                         
                                                                                                                                                                
    IF ENQUEUE_GET_REL(AUDIT_TRAIL_AUD_STD, 2 ) = 1 THEN                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                    
                          'SYSTEM.AUD$: Enqueue Release error, ORA-46264');                                                                                     
      RAISE_ORA_ERROR(46264);                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  FUNCTION TBS_SPACE_CHECK                                                                                                                                      
           (AUDIT_TRAIL_TBS            IN  VARCHAR2,                                                                                                            
            AUDIT_TABLE_OWNER          IN  VARCHAR2,                                                                                                            
            AUDIT_TABLE_NAME           IN  VARCHAR2,                                                                                                            
            FACTOR_NEW_RECS            IN  PLS_INTEGER,                                                                                                         
            SPACE_OCCUPIED             OUT NUMBER,                                                                                                              
            SPACE_REQUIRED             OUT NUMBER,                                                                                                              
            SPACE_AVAILABLE            OUT NUMBER                                                                                                               
           )                                                                                                                                                    
  RETURN   BOOLEAN                                                                                                                                              
  IS                                                                                                                                                            
    TAB_ROWS        NUMBER := 0;                                                                                                                                
    TEMP_ROWS       NUMBER := 0;                                                                                                                                
    EXTRA_ROWS      NUMBER := 0;                                                                                                                                
    SPACE_OCC       NUMBER := 0;                                                                                                                                
    SPACE_REQ       NUMBER := 0;                                                                                                                                
    TBS_SPACE_AVAIL NUMBER := 0;                                                                                                                                
    TBS_BLK_SIZE    NUMBER := 0;                                                                                                                                
    BLOCKS_USED     NUMBER := 0;                                                                                                                                
    BLOCK_SIZE      NUMBER := 0;                                                                                                                                
    M_PART_CNT      NUMBER := 0;                                                                                                                                
    DIV_QUOTIENT    NUMBER := 0;                                                                                                                                
    M_TRACE_MSG     VARCHAR2(200);                                                                                                                              
    CURSOR SEL_DBA_PAR (TAB_OWNER VARCHAR2, TAB_NAME VARCHAR2) IS                                                                                               
      SELECT PARTITION_POSITION, PARTITION_NAME, TABLESPACE_NAME                                                                                                
      FROM DBA_TAB_PARTITIONS                                                                                                                                   
      WHERE TABLE_NAME = TAB_NAME AND                                                                                                                           
            TABLE_OWNER = TAB_OWNER                                                                                                                             
      ORDER BY PARTITION_POSITION;                                                                                                                              
    OLS_CONFLICT      EXCEPTION;                                                                                                                                
    PRAGMA EXCEPTION_INIT(OLS_CONFLICT, -20011);                                                                                                                
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In tbs_space_check');                                                                                              
                                                                                                                                                                
    IF AUDIT_TABLE_NAME <> 'AUD$' AND                                                                                                                           
       AUDIT_TABLE_NAME <> 'FGA_LOG$' THEN                                                                                                                      
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: ' ||                                                                                                   
                          AUDIT_TABLE_NAME);                                                                                                                    
      RAISE_ORA_ERROR(46250, AUDIT_TABLE_NAME);                                                                                                                 
    END IF;                                                                                                                                                     
                                                                                                                                                                
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'Space check for ' ||                                                                                                
                        AUDIT_TABLE_NAME);                                                                                                                      
    BEGIN                                                                                                                                                       
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
      DBMS_PDB_EXEC_SQL('DROP TABLE '||                                                                                                                         
                        DBMS_ASSERT.ENQUOTE_NAME(AUDIT_TABLE_OWNER,FALSE) ||                                                                                    
                        '.DAM_TEMP_'|| AUDIT_TABLE_NAME);                                                                                                       
      COMMIT;                                                                                                                                                   
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                    
                    'Dropped '||AUDIT_TABLE_OWNER||'.DAM_TEMP_'||                                                                                               
                     AUDIT_TABLE_NAME);                                                                                                                         
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        NULL;                                                                                                                                                   
    END;                                                                                                                                                        
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      SELECT BLOCK_SIZE INTO TBS_BLK_SIZE FROM DBA_TABLESPACES                                                                                                  
      WHERE TABLESPACE_NAME = NLS_UPPER(AUDIT_TRAIL_TBS);                                                                                                       
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                  
                            'Invalid Tablespace - ORA-46262');                                                                                                  
        RAISE_ORA_ERROR(46262, AUDIT_TRAIL_TBS);                                                                                                                
    END;                                                                                                                                                        
                                                                                                                                                                
    M_TRACE_MSG := 'Tablespace ''' || AUDIT_TRAIL_TBS || ''' has '''                                                                                            
                   || TBS_BLK_SIZE || ''' blocksize ';                                                                                                          
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, M_TRACE_MSG);                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    IF FACTOR_NEW_RECS < 0 THEN                                                                                                                                 
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46251: FACTOR_NEW_RECS');                                                                                     
      RAISE_ORA_ERROR(46251, 'FACTOR_NEW_RECS');                                                                                                                
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_TRACE_MSG := 'Factor ''' || FACTOR_NEW_RECS || ''' ';                                                                                                     
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, M_TRACE_MSG);                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      DBMS_STATS.GATHER_TABLE_STATS(AUDIT_TABLE_OWNER, AUDIT_TABLE_NAME);                                                                                       
    EXCEPTION                                                                                                                                                   
      WHEN OLS_CONFLICT THEN                                                                                                                                    
        M_TRACE_MSG := 'ORA-46275: ' || AUDIT_TABLE_OWNER || '.'                                                                                                
                       || AUDIT_TABLE_NAME;                                                                                                                     
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, M_TRACE_MSG);                                                                                                    
        RAISE_ORA_ERROR(46275, AUDIT_TABLE_OWNER || '.' || AUDIT_TABLE_NAME);                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    SELECT COUNT(PARTITION_POSITION) INTO M_PART_CNT                                                                                                            
    FROM DBA_TAB_PARTITIONS                                                                                                                                     
    WHERE TABLE_NAME = AUDIT_TABLE_NAME;                                                                                                                        
                                                                                                                                                                
    IF M_PART_CNT <= 0                                                                                                                                          
    THEN                                                                                                                                                        
                                                                                                                                                                
      SELECT BLOCK_SIZE INTO BLOCK_SIZE FROM DBA_TABLESPACES                                                                                                    
      WHERE TABLESPACE_NAME =                                                                                                                                   
      (SELECT TABLESPACE_NAME FROM DBA_TABLES WHERE TABLE_NAME =                                                                                                
                               AUDIT_TABLE_NAME);                                                                                                               
                                                                                                                                                                
      SELECT BLOCKS INTO BLOCKS_USED FROM DBA_TABLES                                                                                                            
      WHERE TABLE_NAME = AUDIT_TABLE_NAME;                                                                                                                      
                                                                                                                                                                
                                                                                                                                                                
      SPACE_OCC := (BLOCKS_USED + 3) * BLOCK_SIZE;                                                                                                              
                                                                                                                                                                
      SELECT NUM_ROWS INTO TAB_ROWS FROM DBA_TABLES                                                                                                             
      WHERE TABLE_NAME = AUDIT_TABLE_NAME;                                                                                                                      
                                                                                                                                                                
      EXTRA_ROWS := TAB_ROWS + ((FACTOR_NEW_RECS * TAB_ROWS) / 100);                                                                                            
                                                                                                                                                                
      IF(TAB_ROWS > 0) THEN                                                                                                                                     
        SPACE_REQ := ROUND((SPACE_OCC * EXTRA_ROWS) / TAB_ROWS);                                                                                                
      ELSE                                                                                                                                                      
        SPACE_REQ := 65536;                                                                                                                                     
      END IF;                                                                                                                                                   
                                                                                                                                                                
    ELSE                                                                                                                                                        
                                                                                                                                                                
      SPACE_OCC := 0;                                                                                                                                           
      TAB_ROWS := 0;                                                                                                                                            
      SPACE_REQ := 0;                                                                                                                                           
      FOR PART_INFO IN SEL_DBA_PAR(AUDIT_TABLE_OWNER, AUDIT_TABLE_NAME) LOOP                                                                                    
        SELECT BLOCK_SIZE INTO BLOCK_SIZE FROM DBA_TABLESPACES                                                                                                  
        WHERE TABLESPACE_NAME = PART_INFO.TABLESPACE_NAME;                                                                                                      
                                                                                                                                                                
        SELECT BLOCKS, NUM_ROWS INTO BLOCKS_USED, TEMP_ROWS                                                                                                     
        FROM DBA_TAB_PARTITIONS                                                                                                                                 
        WHERE TABLE_NAME = AUDIT_TABLE_NAME;                                                                                                                    
                                                                                                                                                                
                                                                                                                                                                
        SPACE_OCC := (BLOCKS_USED + 3) * BLOCK_SIZE;                                                                                                            
                                                                                                                                                                
        TAB_ROWS := TAB_ROWS + TEMP_ROWS;                                                                                                                       
                                                                                                                                                                
        IF(TEMP_ROWS > 0) THEN                                                                                                                                  
          SPACE_REQ := SPACE_REQ + SPACE_OCC;                                                                                                                   
        END IF;                                                                                                                                                 
      END LOOP;                                                                                                                                                 
                                                                                                                                                                
      EXTRA_ROWS := ((FACTOR_NEW_RECS * TAB_ROWS) / 100);                                                                                                       
      IF(EXTRA_ROWS > 0 AND TAB_ROWS  > 0) THEN                                                                                                                 
                                                                                                                                                                
        SPACE_OCC := (3 * BLOCK_SIZE);                                                                                                                          
        SPACE_REQ := SPACE_REQ +                                                                                                                                
                         ROUND((SPACE_OCC * EXTRA_ROWS) / TAB_ROWS);                                                                                            
      ELSE                                                                                                                                                      
        SPACE_REQ := 65536;                                                                                                                                     
      END IF;                                                                                                                                                   
                                                                                                                                                                
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    DIV_QUOTIENT := SPACE_REQ / 65536;                                                                                                                          
    SPACE_REQ := CEIL(DIV_QUOTIENT) * 65536;                                                                                                                    
                                                                                                                                                                
    M_TRACE_MSG := AUDIT_TABLE_NAME || ': Space occupied = ' || SPACE_OCC ||                                                                                    
                   ' per row, space required = ' || SPACE_REQ;                                                                                                  
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, M_TRACE_MSG);                                                                                                        
                                                                                                                                                                
    SPACE_OCCUPIED := SPACE_OCC;                                                                                                                                
    SPACE_REQUIRED := SPACE_REQ;                                                                                                                                
                                                                                                                                                                
    SELECT SUM(BYTES) INTO TBS_SPACE_AVAIL FROM DBA_FREE_SPACE                                                                                                  
    WHERE TABLESPACE_NAME = NLS_UPPER(AUDIT_TRAIL_TBS);                                                                                                         
                                                                                                                                                                
    M_TRACE_MSG := 'Space available = ' || TBS_SPACE_AVAIL;                                                                                                     
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, M_TRACE_MSG);                                                                                                        
                                                                                                                                                                
    SPACE_AVAILABLE := TBS_SPACE_AVAIL;                                                                                                                         
                                                                                                                                                                
    IF SPACE_REQUIRED > TBS_SPACE_AVAIL THEN                                                                                                                    
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'tbs_space_check: return FALSE');                                                                                  
      RETURN FALSE;                                                                                                                                             
    ELSE                                                                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'tbs_space_check: return TRUE');                                                                                   
      RETURN TRUE;                                                                                                                                              
    END IF;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_AUDIT_TRAIL_LOCATION_ANG                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_LOCATION_VALUE IN VARCHAR2                                                                                                             
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_TBS_NAME       VARCHAR2(32);                                                                                                                              
    M_TBS_STATUS     VARCHAR2(10);                                                                                                                              
    M_TBS_STORAGE    VARCHAR2(10);                                                                                                                              
    LOW_TBSP         EXCEPTION;                                                                                                                                 
    PRAGMA EXCEPTION_INIT(LOW_TBSP, -1658);                                                                                                                     
                                                                                                                                                                
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_audit_trail_location_ang');                                                                                 
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE <> AUDIT_TRAIL_UNIFIED THEN                                                                                                             
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250');                                                                                                      
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_LOCATION_VALUE IS NULL OR                                                                                                                    
       LENGTH(AUDIT_TRAIL_LOCATION_VALUE) = 0 OR                                                                                                                
       LENGTH(AUDIT_TRAIL_LOCATION_VALUE) > 30                                                                                                                  
    THEN                                                                                                                                                        
      WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR,                                                                                                                    
                          'ORA-46250: AUDIT_TRAIL_LOCATION_VALUE');                                                                                             
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_LOCATION_VALUE');                                                                                                     
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_TBS_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(AUDIT_TRAIL_LOCATION_VALUE);                                                                                    
      M_TBS_NAME := NLS_UPPER(M_TBS_NAME);                                                                                                                      
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46250: SQL_NAME');                                                                                          
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_LOCATION_VALUE');                                                                                                   
    END;                                                                                                                                                        
                                                                                                                                                                
    IF IS_READ_WRITE THEN                                                                                                                                       
      IF M_UNIAUD_LCK_HDL IS NULL THEN                                                                                                                          
          DBMS_LOCK.ALLOCATE_UNIQUE(UNIAUD_OP, M_UNIAUD_LCK_HDL);                                                                                               
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF DBMS_LOCK.REQUEST(M_UNIAUD_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                  
                             0  ) <> 0 THEN                                                                                                                     
          RAISE_ORA_ERROR(46277);                                                                                                                               
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      SELECT STATUS, SEGMENT_SPACE_MANAGEMENT INTO M_TBS_STATUS, M_TBS_STORAGE                                                                                  
      FROM DBA_TABLESPACES WHERE TABLESPACE_NAME = M_TBS_NAME;                                                                                                  
                                                                                                                                                                
      IF UPPER(M_TBS_STATUS) <> 'ONLINE' THEN                                                                                                                   
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'TS offline');                                                                                                   
        RAISE_ORA_ERROR(46262, M_TBS_NAME);                                                                                                                     
      END IF;                                                                                                                                                   
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'TS error');                                                                                                     
        RAISE_ORA_ERROR(46262, M_TBS_NAME);                                                                                                                     
    END;                                                                                                                                                        
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      IF M_TBS_STORAGE = 'AUTO' THEN                                                                                                                            
         SETUP_NG_AUDIT_TSPACE(M_TBS_NAME, 1 );                                                                                                                 
      ELSE                                                                                                                                                      
         SETUP_NG_AUDIT_TSPACE(M_TBS_NAME, 2 );                                                                                                                 
      END IF;                                                                                                                                                   
    EXCEPTION                                                                                                                                                   
      WHEN LOW_TBSP THEN                                                                                                                                        
        WRITE_TRACE_MESSAGE(TRACE_LEVEL_ERROR, 'ORA-46267...1');                                                                                                
        RAISE_ORA_ERROR(46267, M_TBS_NAME);                                                                                                                     
      WHEN OTHERS THEN                                                                                                                                          
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    MERGE INTO SYS.DAM_CONFIG_PARAM$ D                                                                                                                          
    USING (SELECT COUNT(*) R_CNT                                                                                                                                
         FROM SYS.DAM_CONFIG_PARAM$                                                                                                                             
         WHERE PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                   
               AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE) S                                                                                                      
                ON (S.R_CNT = 1)                                                                                                                                
    WHEN MATCHED THEN                                                                                                                                           
         UPDATE SET D.STRING_VALUE = M_TBS_NAME                                                                                                                 
         WHERE D.PARAM_ID = DB_AUDIT_TABLEPSACE                                                                                                                 
           AND D.AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE                                                                                                           
    WHEN NOT MATCHED THEN                                                                                                                                       
         INSERT VALUES(DB_AUDIT_TABLEPSACE, AUDIT_TRAIL_TYPE, NULL,                                                                                             
                       M_TBS_NAME);                                                                                                                             
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
    UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_TYPE, DB_AUDIT_TABLEPSACE);                                                                                              
                                                                                                                                                                
    IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                            
      NULL;                                                                                                                                                     
    END IF;                                                                                                                                                     
    M_UNIAUD_LCK_HDL := NULL;                                                                                                                                   
                                                                                                                                                                
  EXCEPTION                                                                                                                                                     
    WHEN OTHERS THEN                                                                                                                                            
      IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                          
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
                                                                                                                                                                
      RAISE;                                                                                                                                                    
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE SET_AUDIT_TRAIL_PROPERTY_ANG                                                                                                                        
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY_VALUE IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In set_audit_trail_property_ang');                                                                                 
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE != AUDIT_TRAIL_UNIFIED THEN                                                                                                             
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE OR                                                                                                                
       AUDIT_TRAIL_PROPERTY = AUDIT_TRAIL_WRITE_MODE                                                                                                            
    THEN                                                                                                                                                        
      NULL;                                                                                                                                                     
                                                                                                                                                                
    ELSE                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PROPERTY');                                                                                                           
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                                
    SET NUMBER_VALUE = AUDIT_TRAIL_PROPERTY_VALUE                                                                                                               
    WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                       
          AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE;                                                                                                             
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY);                                                                                             
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAR_AUDIT_TRAIL_PROPERTY_ANG                                                                                                                      
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PROPERTY       IN PLS_INTEGER,                                                                                                         
             USE_DEFAULT_VALUES         IN BOOLEAN := FALSE                                                                                                     
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_PROP_VALUE        NUMBER := 0;                                                                                                                            
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG,                                                                                                                      
                        ' In clear_audit_trail_property_ang');                                                                                                  
                                                                                                                                                                
    IF AUDIT_TRAIL_TYPE != AUDIT_TRAIL_UNIFIED THEN                                                                                                             
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_TYPE');                                                                                                               
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE OR                                                                                                               
       AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE OR                                                                                                                
       AUDIT_TRAIL_PROPERTY = AUDIT_TRAIL_WRITE_MODE                                                                                                            
    THEN                                                                                                                                                        
      NULL;                                                                                                                                                     
                                                                                                                                                                
    ELSE                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PROPERTY');                                                                                                           
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF USE_DEFAULT_VALUES = FALSE THEN                                                                                                                          
                                                                                                                                                                
      IF AUDIT_TRAIL_PROPERTY = AUDIT_TRAIL_WRITE_MODE THEN                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PROPERTY');                                                                                                         
      ELSE                                                                                                                                                      
        M_PROP_VALUE := 0;                                                                                                                                      
      END IF;                                                                                                                                                   
                                                                                                                                                                
    ELSE                                                                                                                                                        
                                                                                                                                                                
      CASE                                                                                                                                                      
        WHEN AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_SIZE THEN                                                                                                       
          M_PROP_VALUE := 10000;                                                                                                                                
        WHEN AUDIT_TRAIL_PROPERTY = OS_FILE_MAX_AGE THEN                                                                                                        
          M_PROP_VALUE := 5;                                                                                                                                    
        WHEN AUDIT_TRAIL_PROPERTY = AUDIT_TRAIL_WRITE_MODE THEN                                                                                                 
          M_PROP_VALUE := AUDIT_TRAIL_QUEUED_WRITE;                                                                                                             
      END CASE;                                                                                                                                                 
                                                                                                                                                                
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    UPDATE SYS.DAM_CONFIG_PARAM$                                                                                                                                
    SET NUMBER_VALUE = M_PROP_VALUE                                                                                                                             
    WHERE PARAM_ID = AUDIT_TRAIL_PROPERTY                                                                                                                       
          AND AUDIT_TRAIL_TYPE# = AUDIT_TRAIL_TYPE;                                                                                                             
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    UPDATE_ATRAIL_PROP_SGA(AUDIT_TRAIL_TYPE, AUDIT_TRAIL_PROPERTY);                                                                                             
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CLEAN_AUDIT_TRAIL_ANG                                                                                                                               
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE                                                                                                      
            )                                                                                                                                                   
  IS                                                                                                                                                            
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, ' In clean_audit_trail_ang');                                                                                        
                                                                                                                                                                
    IF IS_READ_WRITE THEN                                                                                                                                       
                                                                                                                                                                
      IF M_UNIAUD_LCK_HDL IS NULL THEN                                                                                                                          
          DBMS_LOCK.ALLOCATE_UNIQUE(UNIAUD_OP, M_UNIAUD_LCK_HDL);                                                                                               
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF DBMS_LOCK.REQUEST(M_UNIAUD_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                  
                             0  ) <> 0 THEN                                                                                                                     
          RAISE_ORA_ERROR(46277);                                                                                                                               
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    CLEAN_AUDIT_TRAIL_INT(AUDIT_TRAIL_UNIFIED,                                                                                                                  
                          USE_LAST_ARCH_TIMESTAMP);                                                                                                             
                                                                                                                                                                
    IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                            
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
                                                                                                                                                                
  EXCEPTION                                                                                                                                                     
    WHEN OTHERS THEN                                                                                                                                            
      IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                          
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
                                                                                                                                                                
      RAISE;                                                                                                                                                    
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE CREATE_PURGE_JOB_ANG                                                                                                                                
            (AUDIT_TRAIL_TYPE           IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_INTERVAL IN PLS_INTEGER,                                                                                                         
             AUDIT_TRAIL_PURGE_NAME     IN VARCHAR2,                                                                                                            
             USE_LAST_ARCH_TIMESTAMP    IN BOOLEAN := TRUE,                                                                                                     
             CONTAINER                  IN PLS_INTEGER                                                                                                          
            )                                                                                                                                                   
  IS                                                                                                                                                            
    M_INTERVAL         VARCHAR2(200);                                                                                                                           
    M_SQL_STMT         VARCHAR2(1000);                                                                                                                          
    M_JOBS             NUMBER := 0;                                                                                                                             
    M_TRAIL_COUNT      NUMBER := 0;                                                                                                                             
    M_SETUP_COUNT      NUMBER := 0;                                                                                                                             
    M_ATRAIL_TYPE      NUMBER := AUDIT_TRAIL_TYPE;                                                                                                              
    M_NEW_JOB_NAME     VARCHAR2(100);                                                                                                                           
  BEGIN                                                                                                                                                         
    WRITE_TRACE_MESSAGE(TRACE_LEVEL_DEBUG, 'In create_purge_job_ang');                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
    IF AUDIT_TRAIL_PURGE_NAME IS NULL OR                                                                                                                        
       LENGTH(AUDIT_TRAIL_PURGE_NAME) = 0 OR                                                                                                                    
       LENGTH(AUDIT_TRAIL_PURGE_NAME) > 100                                                                                                                     
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                         
    END IF;                                                                                                                                                     
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      M_NEW_JOB_NAME := DBMS_ASSERT.SIMPLE_SQL_NAME(AUDIT_TRAIL_PURGE_NAME);                                                                                    
    EXCEPTION                                                                                                                                                   
      WHEN OTHERS THEN                                                                                                                                          
        RAISE_ORA_ERROR(46250, 'AUDIT_TRAIL_PURGE_NAME');                                                                                                       
    END;                                                                                                                                                        
                                                                                                                                                                
    IF AUDIT_TRAIL_PURGE_INTERVAL <= 0 OR                                                                                                                       
       AUDIT_TRAIL_PURGE_INTERVAL >= 1000                                                                                                                       
    THEN                                                                                                                                                        
      RAISE_ORA_ERROR(46251, 'AUDIT_TRAIL_PURGE_INTERVAL');                                                                                                     
    END IF;                                                                                                                                                     
                                                                                                                                                                
                                                                                                                                                                
    SELECT COUNT(JOB_NAME) INTO M_JOBS FROM SYS.DAM_CLEANUP_JOBS$                                                                                               
    WHERE JOB_NAME = NLS_UPPER(M_NEW_JOB_NAME);                                                                                                                 
                                                                                                                                                                
    IF M_JOBS >= 1 THEN                                                                                                                                         
      RAISE_ORA_ERROR(46254, M_NEW_JOB_NAME);                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    IF USE_LAST_ARCH_TIMESTAMP = TRUE THEN                                                                                                                      
      M_SQL_STMT := 'BEGIN ' ||                                                                                                                                 
                    'DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL('||                                                                                                      
                    M_ATRAIL_TYPE || ', ' ||                                                                                                                    
                    'TRUE); '                                                                                                                                   
                    || ' END;';                                                                                                                                 
    ELSE                                                                                                                                                        
      M_SQL_STMT := 'BEGIN ' ||                                                                                                                                 
                    'DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL('||                                                                                                      
                    M_ATRAIL_TYPE || ', ' ||                                                                                                                    
                    'FALSE); '                                                                                                                                  
                    || ' END;';                                                                                                                                 
    END IF;                                                                                                                                                     
                                                                                                                                                                
    M_INTERVAL := 'FREQ=HOURLY;INTERVAL=';                                                                                                                      
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      DBMS_SCHEDULER.CREATE_JOB (                                                                                                                               
        JOB_NAME           =>  M_NEW_JOB_NAME,                                                                                                                  
        JOB_TYPE           =>  'PLSQL_BLOCK',                                                                                                                   
        JOB_ACTION         =>  M_SQL_STMT,                                                                                                                      
        REPEAT_INTERVAL    =>  M_INTERVAL || AUDIT_TRAIL_PURGE_INTERVAL,                                                                                        
        COMMENTS           =>  'Audit clean job = ''' ||                                                                                                        
                                M_NEW_JOB_NAME || '''');                                                                                                        
    END;                                                                                                                                                        
                                                                                                                                                                
                                                                                                                                                                
    DBMS_SCHEDULER.ENABLE(M_NEW_JOB_NAME);                                                                                                                      
                                                                                                                                                                
    INSERT INTO SYS.DAM_CLEANUP_JOBS$ VALUES                                                                                                                    
    (NLS_UPPER(M_NEW_JOB_NAME), 1 , M_ATRAIL_TYPE,                                                                                                              
     AUDIT_TRAIL_PURGE_INTERVAL, M_INTERVAL||AUDIT_TRAIL_PURGE_INTERVAL);                                                                                       
                                                                                                                                                                
    COMMIT;                                                                                                                                                     
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
  PROCEDURE LOAD_UNIFIED_AUDIT_FILES                                                                                                                            
            (CONTAINER                  IN PLS_INTEGER := CONTAINER_CURRENT)                                                                                    
  IS                                                                                                                                                            
    M_SQL_TXT   VARCHAR2(1024);                                                                                                                                 
    M_TBS       VARCHAR2(128);                                                                                                                                  
    M_SELVALUE  VARCHAR2(128);                                                                                                                                  
  BEGIN                                                                                                                                                         
    IF IS_READ_WRITE THEN                                                                                                                                       
                                                                                                                                                                
      IF M_UNIAUD_LCK_HDL IS NULL THEN                                                                                                                          
        DBMS_LOCK.ALLOCATE_UNIQUE(UNIAUD_OP, M_UNIAUD_LCK_HDL);                                                                                                 
      END IF;                                                                                                                                                   
                                                                                                                                                                
      IF DBMS_LOCK.REQUEST(M_UNIAUD_LCK_HDL, DBMS_LOCK.X_MODE,                                                                                                  
                             0  ) <> 0 THEN                                                                                                                     
          RAISE_ORA_ERROR(46277);                                                                                                                               
      END IF;                                                                                                                                                   
    ELSE                                                                                                                                                        
      IF CONTAINER <> CONTAINER_ALL THEN                                                                                                                        
        RAISE_ORA_ERROR(46367, NULL);                                                                                                                           
      END IF;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    SELECT PARAMETER_VALUE INTO M_SELVALUE FROM DBA_AUDIT_MGMT_CONFIG_PARAMS                                                                                    
    WHERE PARAMETER_NAME = 'DB AUDIT TABLESPACE' AND                                                                                                            
          AUDIT_TRAIL = 'UNIFIED AUDIT TRAIL';                                                                                                                  
                                                                                                                                                                
    M_TBS := DBMS_ASSERT.SIMPLE_SQL_NAME(M_SELVALUE);                                                                                                           
                                                                                                                                                                
    BEGIN                                                                                                                                                       
      SELECT STATUS INTO M_SELVALUE FROM DBA_TABLESPACES                                                                                                        
      WHERE TABLESPACE_NAME = M_TBS;                                                                                                                            
                                                                                                                                                                
      IF UPPER(M_SELVALUE) <> 'ONLINE' THEN                                                                                                                     
        RAISE_ORA_ERROR(46274, M_TBS);                                                                                                                          
      END IF;                                                                                                                                                   
    EXCEPTION                                                                                                                                                   
      WHEN NO_DATA_FOUND THEN                                                                                                                                   
        RAISE_ORA_ERROR(46274, '');                                                                                                                             
      WHEN OTHERS THEN                                                                                                                                          
        RAISE;                                                                                                                                                  
    END;                                                                                                                                                        
                                                                                                                                                                
    IF SHOULD_DBC_PROPOGATE(CONTAINER) THEN                                                                                                                     
      M_SQL_TXT := 'begin sys.dbms_audit_mgmt.load_unified_audit_files; end;';                                                                                  
      DO_DBC_PROPOGATE(M_SQL_TXT);                                                                                                                              
                                                                                                                                                                
      IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                          
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
                                                                                                                                                                
      RETURN;                                                                                                                                                   
    END IF;                                                                                                                                                     
                                                                                                                                                                
    LOAD_UNIFIED_AUDIT_FILES_INT;                                                                                                                               
                                                                                                                                                                
    IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                            
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
  EXCEPTION                                                                                                                                                     
    WHEN OTHERS THEN                                                                                                                                            
      IF DBMS_LOCK.RELEASE(M_UNIAUD_LCK_HDL) <> 0 THEN                                                                                                          
        NULL;                                                                                                                                                   
      END IF;                                                                                                                                                   
      M_UNIAUD_LCK_HDL := NULL;                                                                                                                                 
                                                                                                                                                                
      RAISE;                                                                                                                                                    
                                                                                                                                                                
  END;                                                                                                                                                          
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                
END DBMS_AUDIT_MGMT;                                                                                                                                            

4603 rows selected.

SQL> spool off
