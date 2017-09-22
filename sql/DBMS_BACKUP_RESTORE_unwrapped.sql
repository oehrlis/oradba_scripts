SQL> select * from table(kt_unwrap.unwrap('DBMS_BACKUP_RESTORE'));
PACKAGE BODY dbms_backup_restore IS                                             
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  GRPC_COUNT  NUMBER       := 0;                                                
                                                                                
                                                                                
  GACTION     VARCHAR2(32) := NULL;                                             
  GMODULE     VARCHAR2(48) := NULL;                                             
  GFUNCTION   NUMBER       := 0;                                                
  GTRACEENABLED NUMBER     := NULL;                                             
  GOVWRTACTION  NUMBER     := 0;                                                
  GFAULTFUNCNO  NUMBER     := 0;                                                
  GFAULTFUNCERR NUMBER     := 0;                                                
  GFAULTFUNCCOUNTER NUMBER := 0;                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  RCIP_DATAFILE_RESTORE   CONSTANT BINARY_INTEGER := 1;                         
  RCIP_DATAFILE_APPLY     CONSTANT BINARY_INTEGER := 2;                         
  RCIP_ARCHIVELOG_RESTORE CONSTANT BINARY_INTEGER := 3;                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  IF_DATAFILE           CONSTANT BINARY_INTEGER :=1;                            
  IF_CONTROLFILE        CONSTANT BINARY_INTEGER :=2;                            
  IF_ARCHIVEDLOG        CONSTANT BINARY_INTEGER :=3;                            
  IF_BACKUPPIECE        CONSTANT BINARY_INTEGER :=4;                            
                                                                                
  INVALID_CALL_SEQUENCE  EXCEPTION;                                             
  PRAGMA EXCEPTION_INIT(INVALID_CALL_SEQUENCE, -99999);                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION  KRBITRC RETURN BINARY_INTEGER;                                      
  FUNCTION  KRBIOVAC RETURN BINARY_INTEGER;                                     
  PROCEDURE KRBIWTRC(TXT IN VARCHAR2);                                          
  PROCEDURE KRBIRERR(ERROR_TO_RAISE NUMBER, MSGTXT IN VARCHAR2);                
  PROCEDURE KRBISLP(SECS IN BINARY_INTEGER);                                    
  PROCEDURE KRBI_SAVE_ACTION(ACTION IN VARCHAR2);                               
  FUNCTION  KRBI_READ_ACTION RETURN VARCHAR2;                                   
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE SETMODULE( MSG  IN  VARCHAR2 DEFAULT NULL ) IS                      
    BEGIN                                                                       
        SYS.DBMS_APPLICATION_INFO.SET_MODULE(MSG, GACTION);                     
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE SETACTION(ACTION IN VARCHAR2) IS                                    
    BEGIN                                                                       
        SYS.DBMS_APPLICATION_INFO.SET_ACTION(ACTION);                           
        KRBI_SAVE_ACTION(ACTION);                                               
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE ICDSTART(FN IN NUMBER                                               
                    ,CHKEVENTS IN BOOLEAN DEFAULT FALSE) IS                     
       SLEEPT    BINARY_INTEGER  := 60;                                         
    BEGIN                                                                       
        IF (GFUNCTION <> 0) THEN                                                
           RAISE INVALID_CALL_SEQUENCE;                                         
        END IF;                                                                 
        IF (GTRACEENABLED IS NULL OR CHKEVENTS) THEN                            
           GTRACEENABLED := KRBITRC();                                          
           GOVWRTACTION  := KRBIOVAC();                                         
        END IF;                                                                 
        GRPC_COUNT := GRPC_COUNT + 1;                                           
        GFUNCTION := FN;                                                        
        IF MOD(GRPC_COUNT, GOVWRTACTION) = 0 THEN                               
                                                                                
           SETACTION('Overwritten');                                            
           IF (GTRACEENABLED <> 0) THEN                                         
              KRBIWTRC('icdstart - Overwrote ACTION in v$session');             
           END IF;                                                              
        ELSE                                                                    
           GACTION := TO_CHAR(GRPC_COUNT, '0000000MI') ||'STARTED'||            
                      TO_CHAR(GFUNCTION, 'FM9999');                             
           SETACTION(GACTION);                                                  
           IF (GTRACEENABLED <> 0) THEN                                         
               KRBIWTRC('icdstart - Action set to '||GACTION);                  
           END IF;                                                              
        END IF;                                                                 
        IF GFAULTFUNCNO = FN THEN                                               
           IF GTRACEENABLED <> 0 THEN                                           
              KRBIWTRC('icdstart - Fault injected function: '||                 
                       TO_CHAR(GFAULTFUNCNO)||' called');                       
           END IF;                                                              
           GFAULTFUNCCOUNTER := GFAULTFUNCCOUNTER - 1;                          
           IF GFAULTFUNCCOUNTER = 0 THEN                                        
              IF GTRACEENABLED <> 0 THEN                                        
                 KRBIWTRC('icdstart - Signalling fake error '||                 
                          TO_CHAR(GFAULTFUNCERR));                              
              END IF;                                                           
              KRBIRERR(GFAULTFUNCERR, NULL);                                    
           ELSIF GTRACEENABLED <> 0 THEN                                        
              KRBIWTRC('icdstart - Will signal error in '||                     
                       TO_CHAR(GFAULTFUNCCOUNTER)||' invocations');             
           END IF;                                                              
        END IF;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE ICDFINISH IS                                                        
    BEGIN                                                                       
        GACTION := TO_CHAR(GRPC_COUNT, '0000000MI') || 'FINISHED' ||            
                   TO_CHAR(GFUNCTION, 'FM9999');                                
        SETACTION(GACTION);                                                     
        IF (GTRACEENABLED <> 0) THEN                                            
            KRBIWTRC('icdfinish - Action set to '||GACTION);                    
        END IF;                                                                 
        GFUNCTION := 0;                                                         
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE CHECK_VERSION(VERSION IN NUMBER,                                    
                          RELEASE IN NUMBER,                                    
                          UPDAT   IN NUMBER,                                    
                          PKG_NAME IN VARCHAR2);                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIDVAC( TYPE    IN  VARCHAR2 DEFAULT NULL                          
                    ,NAME    IN  VARCHAR2 DEFAULT NULL                          
                    ,IDENT   IN  VARCHAR2 DEFAULT NULL                          
                    ,NOIO    IN  BOOLEAN  DEFAULT FALSE                         
                    ,PARAMS  IN  VARCHAR2 DEFAULT NULL                          
                    ,NODE    OUT VARCHAR2                                       
                    ,DUPCNT  IN  BINARY_INTEGER                                 
                    ,TRACE   IN  BINARY_INTEGER)                                
  RETURN VARCHAR2;                                                              
  PRAGMA INTERFACE (C, KRBIDVAC);                                               
                                                                                
  FUNCTION DEVICEALLOCATE( TYPE    IN  VARCHAR2 DEFAULT NULL                    
                          ,NAME    IN  VARCHAR2 DEFAULT NULL                    
                          ,IDENT   IN  VARCHAR2 DEFAULT NULL                    
                          ,NOIO    IN  BOOLEAN  DEFAULT FALSE                   
                          ,PARAMS  IN  VARCHAR2 DEFAULT NULL )                  
  RETURN VARCHAR2 IS                                                            
        RETURNTYPE  VARCHAR2(80);                                               
        NODE        VARCHAR2(255);                                              
    BEGIN                                                                       
        RETURNTYPE := DEVICEALLOCATE(TYPE, NAME, IDENT, NOIO, PARAMS, NODE,     
                                     1, 0);                                     
        RETURN RETURNTYPE;                                                      
    END DEVICEALLOCATE;                                                         
                                                                                
  FUNCTION DEVICEALLOCATE( TYPE    IN  VARCHAR2 DEFAULT NULL                    
                          ,NAME    IN  VARCHAR2 DEFAULT NULL                    
                          ,IDENT   IN  VARCHAR2 DEFAULT NULL                    
                          ,NOIO    IN  BOOLEAN  DEFAULT FALSE                   
                          ,PARAMS  IN  VARCHAR2 DEFAULT NULL                    
                          ,NODE    OUT VARCHAR2                                 
                          ,DUPCNT  IN  BINARY_INTEGER                           
                          ,TRACE   IN  BINARY_INTEGER DEFAULT 0)                
                                                                                
  RETURN VARCHAR2 IS                                                            
        RETURNTYPE  VARCHAR2(80);                                               
    BEGIN                                                                       
        ICDSTART(1, CHKEVENTS=>TRUE);                                           
        RETURNTYPE := KRBIDVAC(TYPE, NAME, IDENT, NOIO, PARAMS, NODE, DUPCNT,   
                                TRACE);                                         
        ICDFINISH;                                                              
        RETURN RETURNTYPE;                                                      
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDVCM( CMD     IN  VARCHAR2                                      
                     ,PARAMS  IN  VARCHAR2 DEFAULT NULL  );                     
  PRAGMA INTERFACE (C, KRBIDVCM);                                               
                                                                                
                                                                                
  PROCEDURE DEVICECOMMAND( CMD     IN  VARCHAR2                                 
                          ,PARAMS  IN  VARCHAR2 DEFAULT NULL ) IS               
    BEGIN                                                                       
        ICDSTART(2);                                                            
        KRBIDVCM(CMD, PARAMS);                                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  FUNCTION KRBIDVQ(QUESTION IN BINARY_INTEGER) RETURN VARCHAR2;                 
  PRAGMA INTERFACE (C, KRBIDVQ);                                                
                                                                                
                                                                                
  FUNCTION DEVICEQUERY(QUESTION IN BINARY_INTEGER) RETURN VARCHAR2 IS           
        RET VARCHAR2(512);                                                      
    BEGIN                                                                       
        ICDSTART(3);                                                            
        RET := KRBIDVQ(QUESTION);                                               
                                                                                
                                                                                
                                                                                
        IF QUESTION = DEVICEQUERY_MAXSIZE THEN                                  
          RET := RET * 1024;                                                    
        END IF;                                                                 
        ICDFINISH;                                                              
        RETURN RET;                                                             
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDVDA( PARAMS  IN  VARCHAR2 DEFAULT NULL );                      
  PRAGMA INTERFACE (C, KRBIDVDA);                                               
                                                                                
                                                                                
  PROCEDURE DEVICEDEALLOCATE( PARAMS  IN  VARCHAR2 DEFAULT NULL ) IS            
    BEGIN                                                                       
        ICDSTART(4);                                                            
        KRBIDVDA(PARAMS);                                                       
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBIDSTA( STATE     OUT  BINARY_INTEGER                             
                     ,TYPE      OUT  VARCHAR2                                   
                     ,NAME      OUT  VARCHAR2                                   
                     ,BUFSZ     OUT  BINARY_INTEGER                             
                     ,BUFCNT    OUT  BINARY_INTEGER                             
                     ,KBYTES    OUT  VARCHAR2                                   
                     ,READRATE  OUT  BINARY_INTEGER                             
                     ,PARALLEL  OUT  BINARY_INTEGER );                          
  PRAGMA INTERFACE (C, KRBIDSTA);                                               
                                                                                
                                                                                
  PROCEDURE DEVICESTATUS( STATE     OUT  BINARY_INTEGER                         
                         ,TYPE      OUT  VARCHAR2                               
                         ,NAME      OUT  VARCHAR2                               
                         ,BUFSZ     OUT  BINARY_INTEGER                         
                         ,BUFCNT    OUT  BINARY_INTEGER                         
                         ,KBYTES    OUT  NUMBER                                 
                         ,READRATE  OUT  BINARY_INTEGER                         
                         ,PARALLEL  OUT  BINARY_INTEGER ) IS                    
        OUTKBYTES VARCHAR2(32);                                                 
    BEGIN                                                                       
        ICDSTART(5);                                                            
        KRBIDSTA(STATE ,TYPE ,NAME ,BUFSZ ,BUFCNT ,OUTKBYTES ,                  
                 READRATE ,PARALLEL);                                           
        KBYTES := OUTKBYTES;                                                    
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISL( NAME   IN  BINARY_INTEGER                                   
                   ,SET    IN  BOOLEAN                                          
                   ,VALUE  IN  OUT  VARCHAR2);                                  
  PRAGMA INTERFACE (C, KRBISL);                                                 
                                                                                
                                                                                
  PROCEDURE SETLIMIT( NAME   IN  BINARY_INTEGER                                 
                     ,VALUE  IN  NUMBER ) IS                                    
        INPUT_NAME   BINARY_INTEGER NOT NULL := 0;                              
        INPUT_VALN   NUMBER(32);                                                
        INPUT_VALUE  VARCHAR2(32);                                              
    BEGIN                                                                       
        ICDSTART(6);                                                            
        INPUT_NAME := NAME;                                                     
                                                                                
        INPUT_VALN := VALUE;                                                    
        INPUT_VALUE := INPUT_VALN;                                              
        KRBISL(INPUT_NAME, TRUE, INPUT_VALUE);                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE GETLIMIT( NAME   IN  BINARY_INTEGER                                 
                     ,VALUE  OUT NUMBER ) IS                                    
        INPUT_NAME     BINARY_INTEGER NOT NULL := 0;                            
        OUTPUT_VALUE   VARCHAR2(32);                                            
    BEGIN                                                                       
        ICDSTART(7);                                                            
        INPUT_NAME := NAME;                                                     
        KRBISL(INPUT_NAME, FALSE, OUTPUT_VALUE);                                
        VALUE := OUTPUT_VALUE;                                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBIRI;                                                             
  PRAGMA INTERFACE (C, KRBIRI);                                                 
                                                                                
                                                                                
  PROCEDURE REINIT IS                                                           
    BEGIN                                                                       
        ICDSTART(8);                                                            
        KRBIRI;                                                                 
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBSDF( SET_STAMP     OUT    NUMBER                               
                     ,SET_COUNT     OUT    NUMBER                               
                     ,NOCHECKSUM    IN     BOOLEAN        DEFAULT FALSE         
                     ,TAG           IN     VARCHAR2       DEFAULT NULL          
                     ,INCREMENTAL   IN     BOOLEAN        DEFAULT FALSE         
                     ,BACKUP_LEVEL  IN     BINARY_INTEGER DEFAULT 0             
                     ,CHECK_LOGICAL IN     BOOLEAN                              
                     ,KEEP_OPTIONS  IN     BINARY_INTEGER                       
                     ,KEEP_UNTIL    IN     NUMBER                               
                     ,IMAGCP        IN     BOOLEAN                              
                     ,CONVERTTO     IN     BOOLEAN                              
                     ,CONVERTFR     IN     BOOLEAN                              
                     ,PLTFRMTO      IN     BINARY_INTEGER                       
                     ,PLTFRMFR      IN     BINARY_INTEGER                       
                     ,SAMEEN        IN     BOOLEAN                              
                     ,CONVERTDB     IN     BOOLEAN                              
                     ,NOCATALOG     IN     BOOLEAN                              
                     ,VALIDATE      IN     BOOLEAN                              
                     ,VALIDATEBLK   IN     BOOLEAN                              
                     ,HDRUPD        IN OUT BOOLEAN);                            
  PRAGMA INTERFACE (C, KRBIBSDF);                                               
                                                                                
                                                                                
  PROCEDURE BACKUPSETDATAFILE( SET_STAMP     OUT  NUMBER                        
                              ,SET_COUNT     OUT  NUMBER                        
                              ,NOCHECKSUM    IN   BOOLEAN         DEFAULT FALSE 
                              ,TAG           IN   VARCHAR2        DEFAULT NULL  
                              ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE 
                              ,BACKUP_LEVEL  IN   BINARY_INTEGER  DEFAULT 0)    
    IS                                                                          
    BEGIN                                                                       
        BACKUPSETDATAFILE(SET_STAMP => SET_STAMP,                               
                          SET_COUNT => SET_COUNT,                               
                          NOCHECKSUM => NOCHECKSUM,                             
                          TAG => TAG,                                           
                          INCREMENTAL => INCREMENTAL,                           
                          BACKUP_LEVEL => BACKUP_LEVEL,                         
                          CHECK_LOGICAL => FALSE,                               
                          KEEP_OPTIONS => 0,                                    
                          KEEP_UNTIL => 0,                                      
                          IMAGCP => FALSE,                                      
                          CONVERTTO => FALSE,                                   
                          CONVERTFR => FALSE,                                   
                          PLTFRMTO => NULL,                                     
                          PLTFRMFR => NULL,                                     
                          SAMEEN   => FALSE,                                    
                          CONVERTDB => FALSE,                                   
                          NOCATALOG => FALSE);                                  
    END;                                                                        
                                                                                
  PROCEDURE BACKUPSETDATAFILE( SET_STAMP     OUT  NUMBER                        
                              ,SET_COUNT     OUT  NUMBER                        
                              ,NOCHECKSUM    IN   BOOLEAN         DEFAULT FALSE 
                              ,TAG           IN   VARCHAR2        DEFAULT NULL  
                              ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE 
                              ,BACKUP_LEVEL  IN   BINARY_INTEGER  DEFAULT 0     
                              ,CHECK_LOGICAL IN   BOOLEAN)                      
    IS                                                                          
    BEGIN                                                                       
        BACKUPSETDATAFILE(SET_STAMP => SET_STAMP,                               
                          SET_COUNT => SET_COUNT,                               
                          NOCHECKSUM => NOCHECKSUM,                             
                          TAG => TAG,                                           
                          INCREMENTAL => INCREMENTAL,                           
                          BACKUP_LEVEL => BACKUP_LEVEL,                         
                          CHECK_LOGICAL => CHECK_LOGICAL,                       
                          KEEP_OPTIONS => 0,                                    
                          KEEP_UNTIL => 0,                                      
                          IMAGCP => FALSE,                                      
                          CONVERTTO => FALSE,                                   
                          CONVERTFR => FALSE,                                   
                          PLTFRMTO => NULL,                                     
                          PLTFRMFR => NULL,                                     
                          SAMEEN   => FALSE,                                    
                          CONVERTDB => FALSE,                                   
                          NOCATALOG => FALSE);                                  
    END;                                                                        
                                                                                
  PROCEDURE BACKUPSETDATAFILE( SET_STAMP     OUT  NUMBER                        
                              ,SET_COUNT     OUT  NUMBER                        
                              ,NOCHECKSUM    IN   BOOLEAN         DEFAULT FALSE 
                              ,TAG           IN   VARCHAR2        DEFAULT NULL  
                              ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE 
                              ,BACKUP_LEVEL  IN   BINARY_INTEGER  DEFAULT 0     
                              ,CHECK_LOGICAL IN   BOOLEAN         DEFAULT FALSE 
                              ,KEEP_OPTIONS  IN   BINARY_INTEGER                
                              ,KEEP_UNTIL    IN   NUMBER)                       
    IS                                                                          
    BEGIN                                                                       
        BACKUPSETDATAFILE(SET_STAMP => SET_STAMP,                               
                          SET_COUNT => SET_COUNT,                               
                          NOCHECKSUM => NOCHECKSUM,                             
                          TAG => TAG,                                           
                          INCREMENTAL => INCREMENTAL,                           
                          BACKUP_LEVEL => BACKUP_LEVEL,                         
                          CHECK_LOGICAL => CHECK_LOGICAL,                       
                          KEEP_OPTIONS => KEEP_OPTIONS,                         
                          KEEP_UNTIL => KEEP_UNTIL,                             
                          IMAGCP => FALSE,                                      
                          CONVERTTO => FALSE,                                   
                          CONVERTFR => FALSE,                                   
                          PLTFRMTO => NULL,                                     
                          PLTFRMFR => NULL,                                     
                          SAMEEN   => FALSE,                                    
                          CONVERTDB => FALSE,                                   
                          NOCATALOG => FALSE);                                  
    END;                                                                        
                                                                                
  PROCEDURE BACKUPSETDATAFILE( SET_STAMP     OUT  NUMBER                        
                              ,SET_COUNT     OUT  NUMBER                        
                              ,NOCHECKSUM    IN   BOOLEAN         DEFAULT FALSE 
                              ,TAG           IN   VARCHAR2        DEFAULT NULL  
                              ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE 
                              ,BACKUP_LEVEL  IN   BINARY_INTEGER  DEFAULT 0     
                              ,CHECK_LOGICAL IN   BOOLEAN         DEFAULT FALSE 
                              ,KEEP_OPTIONS  IN   BINARY_INTEGER  DEFAULT 0     
                              ,KEEP_UNTIL    IN   NUMBER          DEFAULT 0     
                              ,IMAGCP        IN   BOOLEAN                       
                              ,CONVERTTO     IN   BOOLEAN                       
                              ,CONVERTFR     IN   BOOLEAN                       
                              ,PLTFRMTO      IN   BINARY_INTEGER                
                              ,PLTFRMFR      IN   BINARY_INTEGER                
                              ,SAMEEN        IN   BOOLEAN)                      
    IS                                                                          
    BEGIN                                                                       
        BACKUPSETDATAFILE(SET_STAMP => SET_STAMP,                               
                          SET_COUNT => SET_COUNT,                               
                          NOCHECKSUM => NOCHECKSUM,                             
                          TAG => TAG,                                           
                          INCREMENTAL => INCREMENTAL,                           
                          BACKUP_LEVEL => BACKUP_LEVEL,                         
                          CHECK_LOGICAL => CHECK_LOGICAL,                       
                          KEEP_OPTIONS => KEEP_OPTIONS,                         
                          KEEP_UNTIL => KEEP_UNTIL,                             
                          IMAGCP => IMAGCP,                                     
                          CONVERTTO => CONVERTTO,                               
                          CONVERTFR => CONVERTFR,                               
                          PLTFRMTO => PLTFRMTO,                                 
                          PLTFRMFR => PLTFRMFR,                                 
                          SAMEEN   => SAMEEN,                                   
                          CONVERTDB => FALSE,                                   
                          NOCATALOG => FALSE);                                  
    END;                                                                        
                                                                                
  PROCEDURE BACKUPSETDATAFILE( SET_STAMP     OUT  NUMBER                        
                              ,SET_COUNT     OUT  NUMBER                        
                              ,NOCHECKSUM    IN   BOOLEAN         DEFAULT FALSE 
                              ,TAG           IN   VARCHAR2        DEFAULT NULL  
                              ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE 
                              ,BACKUP_LEVEL  IN   BINARY_INTEGER  DEFAULT 0     
                              ,CHECK_LOGICAL IN   BOOLEAN         DEFAULT FALSE 
                              ,KEEP_OPTIONS  IN   BINARY_INTEGER  DEFAULT 0     
                              ,KEEP_UNTIL    IN   NUMBER          DEFAULT 0     
                              ,IMAGCP        IN   BOOLEAN                       
                              ,CONVERTTO     IN   BOOLEAN                       
                              ,CONVERTFR     IN   BOOLEAN                       
                              ,PLTFRMTO      IN   BINARY_INTEGER                
                              ,PLTFRMFR      IN   BINARY_INTEGER                
                              ,SAMEEN        IN   BOOLEAN                       
                              ,CONVERTDB     IN   BOOLEAN)                      
    IS                                                                          
    BEGIN                                                                       
        BACKUPSETDATAFILE(SET_STAMP => SET_STAMP,                               
                          SET_COUNT => SET_COUNT,                               
                          NOCHECKSUM => NOCHECKSUM,                             
                          TAG => TAG,                                           
                          INCREMENTAL => INCREMENTAL,                           
                          BACKUP_LEVEL => BACKUP_LEVEL,                         
                          CHECK_LOGICAL => CHECK_LOGICAL,                       
                          KEEP_OPTIONS => KEEP_OPTIONS,                         
                          KEEP_UNTIL => KEEP_UNTIL,                             
                          IMAGCP => IMAGCP,                                     
                          CONVERTTO => CONVERTTO,                               
                          CONVERTFR => CONVERTFR,                               
                          PLTFRMTO => PLTFRMTO,                                 
                          PLTFRMFR => PLTFRMFR,                                 
                          SAMEEN   => SAMEEN,                                   
                          CONVERTDB => CONVERTDB,                               
                          NOCATALOG => FALSE);                                  
    END;                                                                        
                                                                                
  PROCEDURE BACKUPSETDATAFILE( SET_STAMP     OUT  NUMBER                        
                              ,SET_COUNT     OUT  NUMBER                        
                              ,NOCHECKSUM    IN   BOOLEAN         DEFAULT FALSE 
                              ,TAG           IN   VARCHAR2        DEFAULT NULL  
                              ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE 
                              ,BACKUP_LEVEL  IN   BINARY_INTEGER  DEFAULT 0     
                              ,CHECK_LOGICAL IN   BOOLEAN         DEFAULT FALSE 
                              ,KEEP_OPTIONS  IN   BINARY_INTEGER  DEFAULT 0     
                              ,KEEP_UNTIL    IN   NUMBER          DEFAULT 0     
                              ,IMAGCP        IN   BOOLEAN                       
                              ,CONVERTTO     IN   BOOLEAN                       
                              ,CONVERTFR     IN   BOOLEAN                       
                              ,PLTFRMTO      IN   BINARY_INTEGER                
                              ,PLTFRMFR      IN   BINARY_INTEGER                
                              ,SAMEEN        IN   BOOLEAN                       
                              ,CONVERTDB     IN   BOOLEAN                       
                              ,NOCATALOG     IN   BOOLEAN)                      
    IS                                                                          
       HDRUPD      BOOLEAN   := FALSE;                                          
    BEGIN                                                                       
        BACKUPSETDATAFILE(SET_STAMP => SET_STAMP,                               
                          SET_COUNT => SET_COUNT,                               
                          NOCHECKSUM => NOCHECKSUM,                             
                          TAG => TAG,                                           
                          INCREMENTAL => INCREMENTAL,                           
                          BACKUP_LEVEL => BACKUP_LEVEL,                         
                          CHECK_LOGICAL => CHECK_LOGICAL,                       
                          KEEP_OPTIONS => KEEP_OPTIONS,                         
                          KEEP_UNTIL => KEEP_UNTIL,                             
                          IMAGCP => IMAGCP,                                     
                          CONVERTTO => CONVERTTO,                               
                          CONVERTFR => CONVERTFR,                               
                          PLTFRMTO => PLTFRMTO,                                 
                          PLTFRMFR => PLTFRMFR,                                 
                          SAMEEN   => SAMEEN,                                   
                          CONVERTDB => CONVERTDB,                               
                          NOCATALOG => NOCATALOG,                               
                          VALIDATE => FALSE,                                    
                          VALIDATEBLK => FALSE,                                 
                          HDRUPD => HDRUPD);                                    
    END;                                                                        
                                                                                
  PROCEDURE BACKUPSETDATAFILE( SET_STAMP     OUT    NUMBER                      
                              ,SET_COUNT     OUT    NUMBER                      
                              ,NOCHECKSUM    IN     BOOLEAN        DEFAULT FALSE
                              ,TAG           IN     VARCHAR2       DEFAULT NULL 
                              ,INCREMENTAL   IN     BOOLEAN        DEFAULT FALSE
                              ,BACKUP_LEVEL  IN     BINARY_INTEGER DEFAULT 0    
                              ,CHECK_LOGICAL IN     BOOLEAN        DEFAULT FALSE
                              ,KEEP_OPTIONS  IN     BINARY_INTEGER DEFAULT 0    
                              ,KEEP_UNTIL    IN     NUMBER         DEFAULT 0    
                              ,IMAGCP        IN     BOOLEAN                     
                              ,CONVERTTO     IN     BOOLEAN                     
                              ,CONVERTFR     IN     BOOLEAN                     
                              ,PLTFRMTO      IN     BINARY_INTEGER              
                              ,PLTFRMFR      IN     BINARY_INTEGER              
                              ,SAMEEN        IN     BOOLEAN                     
                              ,CONVERTDB     IN     BOOLEAN                     
                              ,NOCATALOG     IN     BOOLEAN                     
                              ,VALIDATE      IN     BOOLEAN                     
                              ,VALIDATEBLK   IN     BOOLEAN                     
                              ,HDRUPD        IN OUT BOOLEAN)                    
    IS                                                                          
        INPUT_NOCHECKSUM BOOLEAN NOT NULL := FALSE;                             
        INPUT_INCREMENTAL BOOLEAN NOT NULL := FALSE;                            
        INPUT_LEVEL BINARY_INTEGER := 0;                                        
        INPUT_CHECK_LOG BOOLEAN NOT NULL := FALSE;                              
        INPUT_KEEPOPT BINARY_INTEGER NOT NULL := 0;                             
        INPUT_KEEPUNT NUMBER NOT NULL := 0;                                     
        INPUT_IMAGCP BOOLEAN NOT NULL := FALSE;                                 
        INPUT_CONVERTTO BOOLEAN NOT NULL := FALSE;                              
        INPUT_CONVERTFR BOOLEAN NOT NULL := FALSE;                              
        INPUT_SAMEEN BOOLEAN NOT NULL := FALSE;                                 
        INPUT_CONVERTDB BOOLEAN NOT NULL := FALSE;                              
        INPUT_NOCATALOG BOOLEAN NOT NULL := FALSE;                              
        INPUT_VALIDATE BOOLEAN NOT NULL := FALSE;                               
        INPUT_VALIDATEBLK BOOLEAN NOT NULL := FALSE;                            
        INPUT_HDRUPD BOOLEAN NOT NULL := FALSE;                                 
    BEGIN                                                                       
        ICDSTART(9, CHKEVENTS=>TRUE);                                           
        INPUT_NOCHECKSUM := NOCHECKSUM;                                         
        INPUT_INCREMENTAL := INCREMENTAL;                                       
        INPUT_LEVEL := BACKUP_LEVEL;                                            
        INPUT_CHECK_LOG := CHECK_LOGICAL;                                       
        INPUT_KEEPOPT := KEEP_OPTIONS;                                          
        INPUT_KEEPUNT := KEEP_UNTIL;                                            
        INPUT_IMAGCP := IMAGCP;                                                 
        INPUT_CONVERTTO := CONVERTTO;                                           
        INPUT_CONVERTFR := CONVERTFR;                                           
        INPUT_SAMEEN := SAMEEN;                                                 
        INPUT_CONVERTDB := CONVERTDB;                                           
        INPUT_NOCATALOG := NOCATALOG;                                           
        INPUT_VALIDATE := VALIDATE;                                             
        INPUT_VALIDATEBLK := VALIDATEBLK;                                       
        INPUT_HDRUPD := HDRUPD;                                                 
        IF CONVERTDB = TRUE   THEN                                              
           SETMODULE('convert datafile');                                       
        ELSIF INCREMENTAL = FALSE  THEN                                         
          SETMODULE('backup full datafile');                                    
        ELSE                                                                    
          SETMODULE('backup incr datafile');                                    
        END IF;                                                                 
                                                                                
        KRBIBSDF(SET_STAMP => SET_STAMP,                                        
                 SET_COUNT => SET_COUNT,                                        
                 NOCHECKSUM => NOCHECKSUM,                                      
                 TAG => TAG,                                                    
                 INCREMENTAL => INCREMENTAL,                                    
                 BACKUP_LEVEL => BACKUP_LEVEL,                                  
                 CHECK_LOGICAL => CHECK_LOGICAL,                                
                 KEEP_OPTIONS => KEEP_OPTIONS,                                  
                 KEEP_UNTIL => KEEP_UNTIL,                                      
                 IMAGCP => IMAGCP,                                              
                 CONVERTTO => CONVERTTO,                                        
                 CONVERTFR => CONVERTFR,                                        
                 PLTFRMTO => PLTFRMTO,                                          
                 PLTFRMFR => PLTFRMFR,                                          
                 SAMEEN   => SAMEEN,                                            
                 CONVERTDB => CONVERTDB,                                        
                 NOCATALOG => NOCATALOG,                                        
                 VALIDATE  => VALIDATE,                                         
                 VALIDATEBLK => VALIDATEBLK,                                    
                 HDRUPD => HDRUPD);                                             
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBSRL( SET_STAMP    OUT  NUMBER                                  
                     ,SET_COUNT    OUT  NUMBER                                  
                     ,NOCHECKSUM   IN   BOOLEAN DEFAULT FALSE                   
                     ,TAG          IN   VARCHAR2                                
                     ,IMAGCP       IN   BOOLEAN                                 
                     ,VALIDATE     IN   BOOLEAN                                 
                     ,KEEP_OPTIONS IN   BINARY_INTEGER                          
                     ,KEEP_UNTIL   IN   NUMBER);                                
  PRAGMA INTERFACE (C, KRBIBSRL);                                               
                                                                                
                                                                                
  PROCEDURE BACKUPSETARCHIVEDLOG( SET_STAMP   OUT  NUMBER                       
                             ,SET_COUNT   OUT  NUMBER                           
                             ,NOCHECKSUM  IN   BOOLEAN DEFAULT FALSE ) IS       
  BEGIN                                                                         
          BACKUPSETARCHIVEDLOG(SET_STAMP, SET_COUNT, NOCHECKSUM, NULL, FALSE);  
  END;                                                                          
                                                                                
  PROCEDURE BACKUPSETARCHIVEDLOG( SET_STAMP     OUT  NUMBER                     
                                 ,SET_COUNT     OUT  NUMBER                     
                                 ,NOCHECKSUM    IN   BOOLEAN DEFAULT FALSE      
                                 ,TAG           IN   VARCHAR2) IS               
  BEGIN                                                                         
          BACKUPSETARCHIVEDLOG(SET_STAMP, SET_COUNT, NOCHECKSUM, TAG, FALSE);   
  END;                                                                          
                                                                                
  PROCEDURE BACKUPSETARCHIVEDLOG( SET_STAMP     OUT  NUMBER                     
                                 ,SET_COUNT     OUT  NUMBER                     
                                 ,NOCHECKSUM    IN   BOOLEAN DEFAULT FALSE      
                                 ,TAG           IN   VARCHAR2                   
                                 ,IMAGCP        IN   BOOLEAN) IS                
  BEGIN                                                                         
          BACKUPSETARCHIVEDLOG(SET_STAMP, SET_COUNT, NOCHECKSUM, TAG,           
                               IMAGCP, FALSE, 0, 0);                            
  END;                                                                          
                                                                                
  PROCEDURE BACKUPSETARCHIVEDLOG( SET_STAMP     OUT  NUMBER                     
                                 ,SET_COUNT     OUT  NUMBER                     
                                 ,NOCHECKSUM    IN   BOOLEAN DEFAULT FALSE      
                                 ,TAG           IN   VARCHAR2                   
                                 ,IMAGCP        IN   BOOLEAN                    
                                 ,VALIDATE      IN   BOOLEAN) IS                
  BEGIN                                                                         
          BACKUPSETARCHIVEDLOG(SET_STAMP, SET_COUNT, NOCHECKSUM, TAG, IMAGCP,   
                               VALIDATE, 0, 0);                                 
  END;                                                                          
                                                                                
  PROCEDURE BACKUPSETARCHIVEDLOG( SET_STAMP     OUT  NUMBER                     
                                 ,SET_COUNT     OUT  NUMBER                     
                                 ,NOCHECKSUM    IN   BOOLEAN DEFAULT FALSE      
                                 ,TAG           IN   VARCHAR2                   
                                 ,IMAGCP        IN   BOOLEAN                    
                                 ,VALIDATE      IN   BOOLEAN                    
                                 ,KEEP_OPTIONS  IN   BINARY_INTEGER             
                                 ,KEEP_UNTIL    IN   NUMBER) IS                 
  BEGIN                                                                         
        ICDSTART(10, CHKEVENTS=>TRUE);                                          
        SETMODULE('backup archivelog');                                         
        KRBIBSRL(SET_STAMP, SET_COUNT, NOCHECKSUM, TAG, IMAGCP, VALIDATE,       
                 KEEP_OPTIONS, KEEP_UNTIL);                                     
        ICDFINISH;                                                              
  EXCEPTION                                                                     
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBDF( DFNUMBER      IN  BINARY_INTEGER                           
                    ,SINCE_CHANGE  IN  NUMBER          DEFAULT 0                
                    ,MAX_CORRUPT   IN  BINARY_INTEGER  DEFAULT 0);              
  PRAGMA INTERFACE (C, KRBIBDF);                                                
                                                                                
                                                                                
  PROCEDURE BACKUPDATAFILE( DFNUMBER      IN  BINARY_INTEGER                    
                           ,SINCE_CHANGE  IN  NUMBER          DEFAULT 0         
                           ,MAX_CORRUPT   IN  BINARY_INTEGER  DEFAULT 0 ) IS    
     INPUT_DFNUMBER  BINARY_INTEGER NOT NULL := 0;                              
  BEGIN                                                                         
     ICDSTART(11);                                                              
     INPUT_DFNUMBER := DFNUMBER;                                                
     KRBIBDF(INPUT_DFNUMBER, SINCE_CHANGE, MAX_CORRUPT);                        
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
  PROCEDURE KRBIBDCP( COPY_RECID    IN  NUMBER                                  
                     ,COPY_STAMP    IN  NUMBER                                  
                     ,SINCE_CHANGE  IN  NUMBER          DEFAULT 0               
                     ,MAX_CORRUPT   IN  BINARY_INTEGER  DEFAULT 0);             
  PRAGMA INTERFACE (C, KRBIBDCP);                                               
                                                                                
  PROCEDURE BACKUPDATAFILECOPY( COPY_RECID    IN  NUMBER                        
                               ,COPY_STAMP    IN  NUMBER                        
                               ,SINCE_CHANGE  IN  NUMBER          DEFAULT 0     
                               ,MAX_CORRUPT   IN  BINARY_INTEGER  DEFAULT 0)    
  IS                                                                            
        RECID  NUMBER     NOT NULL := 0;                                        
        STAMP  NUMBER     NOT NULL := 0;                                        
    BEGIN                                                                       
        ICDSTART(12);                                                           
        RECID := COPY_RECID;                                                    
        STAMP := COPY_STAMP;                                                    
        KRBIBDCP(RECID, STAMP, SINCE_CHANGE, MAX_CORRUPT);                      
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBCF( CFNAME      IN VARCHAR2 DEFAULT NULL                       
                    ,ISSTBY      IN BOOLEAN                                     
                    ,SNAPSHOT_CF IN BOOLEAN);                                   
  PRAGMA INTERFACE (C, KRBIBCF);                                                
                                                                                
                                                                                
  PROCEDURE BACKUPCONTROLFILE( CFNAME  IN  VARCHAR2  DEFAULT NULL ) IS          
    BEGIN                                                                       
        BACKUPCONTROLFILE(CFNAME, FALSE);                                       
    END;                                                                        
                                                                                
  PROCEDURE BACKUPCONTROLFILE( CFNAME  IN  VARCHAR2  DEFAULT NULL               
                              ,ISSTBY  IN  BOOLEAN ) IS                         
    SNAPSHOT_CF BOOLEAN := FALSE;                                               
    BEGIN                                                                       
        IF (CFNAME IS NULL) THEN                                                
           SNAPSHOT_CF := TRUE;                                                 
        END IF;                                                                 
                                                                                
        BACKUPCONTROLFILE(CFNAME, ISSTBY, SNAPSHOT_CF);                         
    END;                                                                        
                                                                                
  PROCEDURE BACKUPCONTROLFILE( CFNAME      IN  VARCHAR2  DEFAULT NULL           
                              ,ISSTBY      IN  BOOLEAN                          
                              ,SNAPSHOT_CF IN  BOOLEAN ) IS                     
    BEGIN                                                                       
        ICDSTART(13);                                                           
        KRBIBCF(CFNAME, ISSTBY, SNAPSHOT_CF);                                   
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBIBRL( ARCH_RECID  IN  NUMBER                                     
                    ,ARCH_STAMP  IN  NUMBER                                     
                    ,DUPLICATE   OUT BOOLEAN);                                  
  PRAGMA INTERFACE (C, KRBIBRL);                                                
                                                                                
                                                                                
  PROCEDURE BACKUPARCHIVEDLOG( ARCH_RECID  IN  NUMBER                           
                          ,ARCH_STAMP  IN  NUMBER ) IS                          
        DUPLICATE BOOLEAN;                                                      
    BEGIN                                                                       
        BACKUPARCHIVEDLOG(ARCH_RECID, ARCH_STAMP, DUPLICATE);                   
    END;                                                                        
  PROCEDURE BACKUPARCHIVEDLOG( ARCH_RECID  IN  NUMBER                           
                          ,ARCH_STAMP  IN  NUMBER                               
                          ,DUPLICATE   OUT BOOLEAN) IS                          
        RECID  NUMBER     NOT NULL := 0;                                        
        STAMP  NUMBER     NOT NULL := 0;                                        
    BEGIN                                                                       
        ICDSTART(14);                                                           
        RECID := ARCH_RECID;                                                    
        STAMP := ARCH_STAMP;                                                    
        KRBIBRL(RECID, STAMP, DUPLICATE);                                       
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBPC( FNAME            IN  VARCHAR2                              
                    ,PIECENO          OUT BINARY_INTEGER                        
                    ,DONE             OUT BOOLEAN                               
                    ,HANDLE           OUT VARCHAR2                              
                    ,COMMENT          OUT VARCHAR2                              
                    ,MEDIA            OUT VARCHAR2                              
                    ,CONCUR           OUT BOOLEAN                               
                    ,PARAMS           IN  VARCHAR2  DEFAULT NULL                
                    ,MEDIA_POOL       IN  BINARY_INTEGER                        
                    ,REUSE            IN  BOOLEAN                               
                    ,SEQUENCE         IN  BINARY_INTEGER                        
                    ,YEAR             IN  BINARY_INTEGER                        
                    ,MONTH            IN  BINARY_INTEGER                        
                    ,DAY              IN  BINARY_INTEGER                        
                    ,ARCHLOG_FAILOVER OUT BOOLEAN                               
                    ,DEFFMT           IN  BINARY_INTEGER                        
                    ,RECID            OUT NUMBER                                
                    ,STAMP            OUT NUMBER                                
                    ,TAG              OUT VARCHAR2                              
                    ,DOCOMPRESS       IN  BOOLEAN                               
                    ,DEST             IN  BINARY_INTEGER                        
                    ,POST10_2         IN  BOOLEAN                               
                    ,NETALIAS         IN  VARCHAR2                              
                    ,COMPRESSALG      IN  VARCHAR2                              
                    ,COMPRESSASOF     IN  NUMBER                                
                    ,COMPRESSLOPT     IN  BINARY_INTEGER);                      
  PRAGMA INTERFACE (C, KRBIBPC);                                                
                                                                                
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME    IN  VARCHAR2                            
                              ,PIECENO  OUT BINARY_INTEGER                      
                              ,DONE     OUT BOOLEAN                             
                              ,HANDLE   OUT VARCHAR2                            
                              ,COMMENT  OUT VARCHAR2                            
                              ,MEDIA    OUT VARCHAR2                            
                              ,CONCUR   OUT BOOLEAN                             
                              ,PARAMS   IN  VARCHAR2  DEFAULT NULL) IS          
        ARCHLOG_FAILOVER BOOLEAN;                                               
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                          ,PIECENO          => PIECENO                          
                          ,DONE             => DONE                             
                          ,HANDLE           => HANDLE                           
                          ,COMMENT          => COMMENT                          
                          ,MEDIA            => MEDIA                            
                          ,CONCUR           => CONCUR                           
                          ,PARAMS           => PARAMS                           
                          ,MEDIA_POOL       => 0                                
                          ,REUSE            => FALSE                            
                          ,SEQUENCE         => NULL                             
                          ,YEAR             => NULL                             
                          ,MONTH_DAY        => NULL                             
                          ,ARCHLOG_FAILOVER => ARCHLOG_FAILOVER);               
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME    IN  VARCHAR2                            
                              ,PIECENO  OUT BINARY_INTEGER                      
                              ,DONE     OUT BOOLEAN                             
                              ,HANDLE   OUT VARCHAR2                            
                              ,COMMENT  OUT VARCHAR2                            
                              ,MEDIA    OUT VARCHAR2                            
                              ,CONCUR   OUT BOOLEAN                             
                              ,PARAMS   IN  VARCHAR2  DEFAULT NULL              
                              ,MEDIA_POOL                                       
                                        IN BINARY_INTEGER ) IS                  
        ARCHLOG_FAILOVER BOOLEAN;                                               
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                          ,PIECENO          => PIECENO                          
                          ,DONE             => DONE                             
                          ,HANDLE           => HANDLE                           
                          ,COMMENT          => COMMENT                          
                          ,MEDIA            => MEDIA                            
                          ,CONCUR           => CONCUR                           
                          ,PARAMS           => PARAMS                           
                          ,MEDIA_POOL       => MEDIA_POOL                       
                          ,REUSE            => FALSE                            
                          ,SEQUENCE         => NULL                             
                          ,YEAR             => NULL                             
                          ,MONTH_DAY        => NULL                             
                          ,ARCHLOG_FAILOVER => ARCHLOG_FAILOVER);               
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME    IN  VARCHAR2                            
                              ,PIECENO  OUT BINARY_INTEGER                      
                              ,DONE     OUT BOOLEAN                             
                              ,HANDLE   OUT VARCHAR2                            
                              ,COMMENT  OUT VARCHAR2                            
                              ,MEDIA    OUT VARCHAR2                            
                              ,CONCUR   OUT BOOLEAN                             
                              ,PARAMS   IN  VARCHAR2  DEFAULT NULL              
                              ,MEDIA_POOL                                       
                                        IN BINARY_INTEGER DEFAULT 0             
                              ,REUSE    IN BOOLEAN) IS                          
        ARCHLOG_FAILOVER BOOLEAN;                                               
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                          ,PIECENO          => PIECENO                          
                          ,DONE             => DONE                             
                          ,HANDLE           => HANDLE                           
                          ,COMMENT          => COMMENT                          
                          ,MEDIA            => MEDIA                            
                          ,CONCUR           => CONCUR                           
                          ,PARAMS           => PARAMS                           
                          ,MEDIA_POOL       => MEDIA_POOL                       
                          ,REUSE            => REUSE                            
                          ,SEQUENCE         => NULL                             
                          ,YEAR             => NULL                             
                          ,MONTH_DAY        => NULL                             
                          ,ARCHLOG_FAILOVER => ARCHLOG_FAILOVER);               
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME    IN  VARCHAR2                            
                              ,PIECENO  OUT BINARY_INTEGER                      
                              ,DONE     OUT BOOLEAN                             
                              ,HANDLE   OUT VARCHAR2                            
                              ,COMMENT  OUT VARCHAR2                            
                              ,MEDIA    OUT VARCHAR2                            
                              ,CONCUR   OUT BOOLEAN                             
                              ,PARAMS   IN  VARCHAR2  DEFAULT NULL              
                              ,SEQUENCE IN  BINARY_INTEGER                      
                              ,YEAR     IN  BINARY_INTEGER                      
                              ,MONTH_DAY                                        
                                        IN  BINARY_INTEGER) IS                  
        ARCHLOG_FAILOVER BOOLEAN;                                               
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                          ,PIECENO          => PIECENO                          
                          ,DONE             => DONE                             
                          ,HANDLE           => HANDLE                           
                          ,COMMENT          => COMMENT                          
                          ,MEDIA            => MEDIA                            
                          ,CONCUR           => CONCUR                           
                          ,PARAMS           => PARAMS                           
                          ,MEDIA_POOL       => 0                                
                          ,REUSE            => FALSE                            
                          ,SEQUENCE         => SEQUENCE                         
                          ,YEAR             => YEAR                             
                          ,MONTH_DAY        => MONTH_DAY                        
                          ,ARCHLOG_FAILOVER => ARCHLOG_FAILOVER);               
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME    IN  VARCHAR2                            
                              ,PIECENO  OUT BINARY_INTEGER                      
                              ,DONE     OUT BOOLEAN                             
                              ,HANDLE   OUT VARCHAR2                            
                              ,COMMENT  OUT VARCHAR2                            
                              ,MEDIA    OUT VARCHAR2                            
                              ,CONCUR   OUT BOOLEAN                             
                              ,PARAMS   IN  VARCHAR2  DEFAULT NULL              
                              ,MEDIA_POOL                                       
                                        IN  BINARY_INTEGER                      
                              ,SEQUENCE IN  BINARY_INTEGER                      
                              ,YEAR     IN  BINARY_INTEGER                      
                              ,MONTH_DAY                                        
                                        IN  BINARY_INTEGER) IS                  
        ARCHLOG_FAILOVER BOOLEAN;                                               
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                          ,PIECENO          => PIECENO                          
                          ,DONE             => DONE                             
                          ,HANDLE           => HANDLE                           
                          ,COMMENT          => COMMENT                          
                          ,MEDIA            => MEDIA                            
                          ,CONCUR           => CONCUR                           
                          ,PARAMS           => PARAMS                           
                          ,MEDIA_POOL       => MEDIA_POOL                       
                          ,REUSE            => FALSE                            
                          ,SEQUENCE         => SEQUENCE                         
                          ,YEAR             => YEAR                             
                          ,MONTH_DAY        => MONTH_DAY                        
                          ,ARCHLOG_FAILOVER => ARCHLOG_FAILOVER);               
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME    IN  VARCHAR2                            
                              ,PIECENO  OUT BINARY_INTEGER                      
                              ,DONE     OUT BOOLEAN                             
                              ,HANDLE   OUT VARCHAR2                            
                              ,COMMENT  OUT VARCHAR2                            
                              ,MEDIA    OUT VARCHAR2                            
                              ,CONCUR   OUT BOOLEAN                             
                              ,PARAMS   IN  VARCHAR2  DEFAULT NULL              
                              ,MEDIA_POOL                                       
                                        IN  BINARY_INTEGER DEFAULT 0            
                              ,REUSE    IN  BOOLEAN                             
                              ,SEQUENCE IN  BINARY_INTEGER                      
                              ,YEAR     IN  BINARY_INTEGER                      
                              ,MONTH_DAY                                        
                                        IN  BINARY_INTEGER) IS                  
        ARCHLOG_FAILOVER BOOLEAN;                                               
    BEGIN                                                                       
        BACKUPPIECECREATE( FNAME            => FNAME                            
                          ,PIECENO          => PIECENO                          
                          ,DONE             => DONE                             
                          ,HANDLE           => HANDLE                           
                          ,COMMENT          => COMMENT                          
                          ,MEDIA            => MEDIA                            
                          ,CONCUR           => CONCUR                           
                          ,PARAMS           => PARAMS                           
                          ,MEDIA_POOL       => MEDIA_POOL                       
                          ,REUSE            => REUSE                            
                          ,SEQUENCE         => SEQUENCE                         
                          ,YEAR             => YEAR                             
                          ,MONTH_DAY        => MONTH_DAY                        
                          ,ARCHLOG_FAILOVER => ARCHLOG_FAILOVER);               
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME      IN  VARCHAR2                          
                              ,PIECENO    OUT BINARY_INTEGER                    
                              ,DONE       OUT BOOLEAN                           
                              ,HANDLE     OUT VARCHAR2                          
                              ,COMMENT    OUT VARCHAR2                          
                              ,MEDIA      OUT VARCHAR2                          
                              ,CONCUR     OUT BOOLEAN                           
                              ,PARAMS     IN  VARCHAR2  DEFAULT NULL            
                              ,MEDIA_POOL IN  BINARY_INTEGER DEFAULT 0          
                              ,REUSE      IN  BOOLEAN DEFAULT FALSE             
                              ,SEQUENCE   IN  BINARY_INTEGER                    
                              ,YEAR       IN  BINARY_INTEGER                    
                              ,MONTH_DAY  IN  BINARY_INTEGER                    
                              ,ARCHLOG_FAILOVER OUT BOOLEAN) IS                 
    LMONTH BINARY_INTEGER := 0;                                                 
    LDAY   BINARY_INTEGER := 0;                                                 
    RECID  NUMBER;                                                              
    STAMP  NUMBER;                                                              
    LTAG   VARCHAR2(32);                                                        
    BEGIN                                                                       
        IF (MONTH_DAY IS NOT NULL) THEN                                         
          LMONTH := FLOOR(MONTH_DAY/100);                                       
          LDAY   := MONTH_DAY - 100 * LMONTH;                                   
        END IF;                                                                 
                                                                                
        BACKUPPIECECREATE( FNAME            => FNAME                            
                          ,PIECENO          => PIECENO                          
                          ,DONE             => DONE                             
                          ,HANDLE           => HANDLE                           
                          ,COMMENT          => COMMENT                          
                          ,MEDIA            => MEDIA                            
                          ,CONCUR           => CONCUR                           
                          ,PARAMS           => PARAMS                           
                          ,MEDIA_POOL       => MEDIA_POOL                       
                          ,REUSE            => REUSE                            
                          ,SEQUENCE         => SEQUENCE                         
                          ,YEAR             => YEAR                             
                          ,MONTH            => LMONTH                           
                          ,DAY              => LDAY                             
                          ,ARCHLOG_FAILOVER => ARCHLOG_FAILOVER                 
                          ,DEFFMT           => 0                                
                          ,RECID            => RECID                            
                          ,STAMP            => STAMP                            
                          ,TAG              => LTAG);                           
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME      IN  VARCHAR2                          
                              ,PIECENO    OUT BINARY_INTEGER                    
                              ,DONE       OUT BOOLEAN                           
                              ,HANDLE     OUT VARCHAR2                          
                              ,COMMENT    OUT VARCHAR2                          
                              ,MEDIA      OUT VARCHAR2                          
                              ,CONCUR     OUT BOOLEAN                           
                              ,PARAMS     IN  VARCHAR2  DEFAULT NULL            
                              ,MEDIA_POOL IN BINARY_INTEGER  DEFAULT 0          
                              ,REUSE      IN BOOLEAN DEFAULT FALSE              
                              ,SEQUENCE   IN BINARY_INTEGER                     
                              ,YEAR       IN BINARY_INTEGER                     
                              ,MONTH      IN BINARY_INTEGER                     
                              ,DAY        IN BINARY_INTEGER                     
                              ,ARCHLOG_FAILOVER OUT BOOLEAN                     
                              ,DEFFMT     IN BINARY_INTEGER                     
                              ,RECID      OUT NUMBER                            
                              ,STAMP      OUT NUMBER                            
                              ,TAG        OUT VARCHAR2) IS                      
    BEGIN                                                                       
        ICDSTART(15, CHKEVENTS=>TRUE);                                          
        KRBIBPC(FNAME, PIECENO, DONE, HANDLE, COMMENT, MEDIA, CONCUR,           
                PARAMS, MEDIA_POOL, REUSE, SEQUENCE, YEAR, MONTH, DAY,          
                ARCHLOG_FAILOVER, DEFFMT, RECID, STAMP, TAG, FALSE, 0,          
                FALSE, NULL, NULL, 1, LOPT_TRUE);                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME      IN  VARCHAR2                          
                              ,PIECENO    OUT BINARY_INTEGER                    
                              ,DONE       OUT BOOLEAN                           
                              ,HANDLE     OUT VARCHAR2                          
                              ,COMMENT    OUT VARCHAR2                          
                              ,MEDIA      OUT VARCHAR2                          
                              ,CONCUR     OUT BOOLEAN                           
                              ,PARAMS     IN  VARCHAR2  DEFAULT NULL            
                              ,MEDIA_POOL IN BINARY_INTEGER  DEFAULT 0          
                              ,REUSE      IN BOOLEAN DEFAULT FALSE              
                              ,ARCHLOG_FAILOVER OUT BOOLEAN                     
                              ,DEFFMT     IN BINARY_INTEGER                     
                              ,RECID      OUT NUMBER                            
                              ,STAMP      OUT NUMBER                            
                              ,TAG        OUT VARCHAR2                          
                              ,DOCOMPRESS IN  BOOLEAN) IS                       
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                         ,PIECENO           => PIECENO                          
                         ,DONE              => DONE                             
                         ,HANDLE            => HANDLE                           
                         ,COMMENT           => COMMENT                          
                         ,MEDIA             => MEDIA                            
                         ,CONCUR            => CONCUR                           
                         ,PARAMS            => PARAMS                           
                         ,MEDIA_POOL        => MEDIA_POOL                       
                         ,REUSE             => REUSE                            
                         ,ARCHLOG_FAILOVER  => ARCHLOG_FAILOVER                 
                         ,DEFFMT            => DEFFMT                           
                         ,RECID             => RECID                            
                         ,STAMP             => STAMP                            
                         ,TAG               => TAG                              
                         ,DOCOMPRESS        => DOCOMPRESS                       
                         ,DEST              => 0                                
                         ,POST10_2          => FALSE);                          
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME      IN  VARCHAR2                          
                              ,PIECENO    OUT BINARY_INTEGER                    
                              ,DONE       OUT BOOLEAN                           
                              ,HANDLE     OUT VARCHAR2                          
                              ,COMMENT    OUT VARCHAR2                          
                              ,MEDIA      OUT VARCHAR2                          
                              ,CONCUR     OUT BOOLEAN                           
                              ,PARAMS     IN  VARCHAR2  DEFAULT NULL            
                              ,MEDIA_POOL IN BINARY_INTEGER  DEFAULT 0          
                              ,REUSE      IN BOOLEAN DEFAULT FALSE              
                              ,ARCHLOG_FAILOVER OUT BOOLEAN                     
                              ,DEFFMT     IN BINARY_INTEGER                     
                              ,RECID      OUT NUMBER                            
                              ,STAMP      OUT NUMBER                            
                              ,TAG        OUT VARCHAR2                          
                              ,DOCOMPRESS IN  BOOLEAN                           
                              ,DEST       IN  BINARY_INTEGER) IS                
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                         ,PIECENO           => PIECENO                          
                         ,DONE              => DONE                             
                         ,HANDLE            => HANDLE                           
                         ,COMMENT           => COMMENT                          
                         ,MEDIA             => MEDIA                            
                         ,CONCUR            => CONCUR                           
                         ,PARAMS            => PARAMS                           
                         ,MEDIA_POOL        => MEDIA_POOL                       
                         ,REUSE             => REUSE                            
                         ,ARCHLOG_FAILOVER  => ARCHLOG_FAILOVER                 
                         ,DEFFMT            => DEFFMT                           
                         ,RECID             => RECID                            
                         ,STAMP             => STAMP                            
                         ,TAG               => TAG                              
                         ,DOCOMPRESS        => DOCOMPRESS                       
                         ,DEST              => DEST                             
                         ,POST10_2          => FALSE);                          
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME      IN  VARCHAR2                          
                              ,PIECENO    OUT BINARY_INTEGER                    
                              ,DONE       OUT BOOLEAN                           
                              ,HANDLE     OUT VARCHAR2                          
                              ,COMMENT    OUT VARCHAR2                          
                              ,MEDIA      OUT VARCHAR2                          
                              ,CONCUR     OUT BOOLEAN                           
                              ,PARAMS     IN  VARCHAR2  DEFAULT NULL            
                              ,MEDIA_POOL IN BINARY_INTEGER  DEFAULT 0          
                              ,REUSE      IN BOOLEAN DEFAULT FALSE              
                              ,ARCHLOG_FAILOVER OUT BOOLEAN                     
                              ,DEFFMT     IN BINARY_INTEGER                     
                              ,RECID      OUT NUMBER                            
                              ,STAMP      OUT NUMBER                            
                              ,TAG        OUT VARCHAR2                          
                              ,DOCOMPRESS IN  BOOLEAN                           
                              ,DEST       IN  BINARY_INTEGER                    
                              ,POST10_2   IN  BOOLEAN) IS                       
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                         ,PIECENO           => PIECENO                          
                         ,DONE              => DONE                             
                         ,HANDLE            => HANDLE                           
                         ,COMMENT           => COMMENT                          
                         ,MEDIA             => MEDIA                            
                         ,CONCUR            => CONCUR                           
                         ,PARAMS            => PARAMS                           
                         ,MEDIA_POOL        => MEDIA_POOL                       
                         ,REUSE             => REUSE                            
                         ,ARCHLOG_FAILOVER  => ARCHLOG_FAILOVER                 
                         ,DEFFMT            => DEFFMT                           
                         ,RECID             => RECID                            
                         ,STAMP             => STAMP                            
                         ,TAG               => TAG                              
                         ,DOCOMPRESS        => DOCOMPRESS                       
                         ,DEST              => DEST                             
                         ,POST10_2          => POST10_2                         
                         ,NETALIAS          => NULL                             
                         ,COMPRESSALG       => NULL                             
                         ,COMPRESSASOF      => 1                                
                         ,COMPRESSLOPT      => LOPT_TRUE);                      
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME       IN  VARCHAR2                         
                              ,PIECENO     OUT BINARY_INTEGER                   
                              ,DONE        OUT BOOLEAN                          
                              ,HANDLE      OUT VARCHAR2                         
                              ,COMMENT     OUT VARCHAR2                         
                              ,MEDIA       OUT VARCHAR2                         
                              ,CONCUR      OUT BOOLEAN                          
                              ,PARAMS      IN  VARCHAR2  DEFAULT NULL           
                              ,MEDIA_POOL  IN BINARY_INTEGER  DEFAULT 0         
                              ,REUSE       IN BOOLEAN DEFAULT FALSE             
                              ,ARCHLOG_FAILOVER OUT BOOLEAN                     
                              ,DEFFMT      IN BINARY_INTEGER                    
                              ,RECID       OUT NUMBER                           
                              ,STAMP       OUT NUMBER                           
                              ,TAG         OUT VARCHAR2                         
                              ,DOCOMPRESS  IN  BOOLEAN                          
                              ,DEST        IN  BINARY_INTEGER                   
                              ,POST10_2    IN  BOOLEAN                          
                              ,NETALIAS    IN  VARCHAR2                         
                              ,COMPRESSALG IN  VARCHAR2) IS                     
    BEGIN                                                                       
       BACKUPPIECECREATE( FNAME             => FNAME                            
                         ,PIECENO           => PIECENO                          
                         ,DONE              => DONE                             
                         ,HANDLE            => HANDLE                           
                         ,COMMENT           => COMMENT                          
                         ,MEDIA             => MEDIA                            
                         ,CONCUR            => CONCUR                           
                         ,PARAMS            => PARAMS                           
                         ,MEDIA_POOL        => MEDIA_POOL                       
                         ,REUSE             => REUSE                            
                         ,ARCHLOG_FAILOVER  => ARCHLOG_FAILOVER                 
                         ,DEFFMT            => DEFFMT                           
                         ,RECID             => RECID                            
                         ,STAMP             => STAMP                            
                         ,TAG               => TAG                              
                         ,DOCOMPRESS        => DOCOMPRESS                       
                         ,DEST              => DEST                             
                         ,POST10_2          => POST10_2                         
                         ,NETALIAS          => NETALIAS                         
                         ,COMPRESSALG       => COMPRESSALG                      
                         ,COMPRESSASOF      => 1                                
                         ,COMPRESSLOPT      => LOPT_TRUE);                      
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END BACKUPPIECECREATE;                                                      
                                                                                
  PROCEDURE BACKUPPIECECREATE( FNAME         IN  VARCHAR2                       
                              ,PIECENO       OUT BINARY_INTEGER                 
                              ,DONE          OUT BOOLEAN                        
                              ,HANDLE        OUT VARCHAR2                       
                              ,COMMENT       OUT VARCHAR2                       
                              ,MEDIA         OUT VARCHAR2                       
                              ,CONCUR        OUT BOOLEAN                        
                              ,PARAMS        IN  VARCHAR2  DEFAULT NULL         
                              ,MEDIA_POOL    IN BINARY_INTEGER  DEFAULT 0       
                              ,REUSE         IN BOOLEAN DEFAULT FALSE           
                              ,ARCHLOG_FAILOVER OUT BOOLEAN                     
                              ,DEFFMT        IN BINARY_INTEGER                  
                              ,RECID         OUT NUMBER                         
                              ,STAMP         OUT NUMBER                         
                              ,TAG           OUT VARCHAR2                       
                              ,DOCOMPRESS    IN  BOOLEAN                        
                              ,DEST          IN  BINARY_INTEGER                 
                              ,POST10_2      IN  BOOLEAN                        
                              ,NETALIAS      IN  VARCHAR2                       
                              ,COMPRESSALG   IN  VARCHAR2                       
                              ,COMPRESSASOF  IN  NUMBER         DEFAULT 1       
                              ,COMPRESSLOPT  IN  BINARY_INTEGER DEFAULT         
                                                              LOPT_TRUE ) IS    
    BEGIN                                                                       
        ICDSTART(16);                                                           
        KRBIBPC(FNAME, PIECENO, DONE, HANDLE, COMMENT, MEDIA, CONCUR,           
                PARAMS, MEDIA_POOL, REUSE, -1, 0, 0, 0,                         
                ARCHLOG_FAILOVER, DEFFMT, RECID, STAMP, TAG, DOCOMPRESS,        
                DEST, POST10_2, NETALIAS, COMPRESSALG, COMPRESSASOF,            
                COMPRESSLOPT);                                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END BACKUPPIECECREATE;                                                      
                                                                                
                                                                                
  PROCEDURE KRBIBDS( COPY_N   IN  BINARY_INTEGER                                
                    ,FNAME    IN  VARCHAR2);                                    
  PRAGMA INTERFACE (C, KRBIBDS);                                                
                                                                                
                                                                                
  PROCEDURE BACKUPPIECECRTDUPSET( COPY_N   IN  BINARY_INTEGER                   
                                 ,FNAME    IN  VARCHAR2) IS                     
    BEGIN                                                                       
        ICDSTART(17);                                                           
        KRBIBDS(COPY_N, FNAME);                                                 
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END BACKUPPIECECRTDUPSET;                                                   
                                                                                
  PROCEDURE KRBIBDG( COPY_N   IN  BINARY_INTEGER                                
                    ,HANDLE   OUT VARCHAR2                                      
                    ,COMMENT  OUT VARCHAR2                                      
                    ,MEDIA    OUT VARCHAR2);                                    
  PRAGMA INTERFACE (C, KRBIBDG);                                                
                                                                                
                                                                                
  PROCEDURE BACKUPPIECECRTDUPGET( COPY_N   IN  BINARY_INTEGER                   
                                 ,HANDLE   OUT VARCHAR2                         
                                 ,COMMENT  OUT VARCHAR2                         
                                 ,MEDIA    OUT VARCHAR2) IS                     
    BEGIN                                                                       
        ICDSTART(18);                                                           
        KRBIBDG(COPY_N, HANDLE, COMMENT, MEDIA);                                
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END BACKUPPIECECRTDUPGET;                                                   
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBV (ARCHLOG_FAILOVER  OUT BOOLEAN                               
                   ,NOCLEANUP         IN  BOOLEAN);                             
  PRAGMA INTERFACE (C, KRBIBV);                                                 
                                                                                
                                                                                
  PROCEDURE BACKUPVALIDATE IS                                                   
    ARCHLOG_FAILOVER   BOOLEAN;                                                 
    BEGIN                                                                       
        BACKUPVALIDATE(ARCHLOG_FAILOVER);                                       
    END;                                                                        
                                                                                
  PROCEDURE BACKUPVALIDATE(ARCHLOG_FAILOVER OUT BOOLEAN) IS                     
    BEGIN                                                                       
        BACKUPVALIDATE(ARCHLOG_FAILOVER, FALSE);                                
    END;                                                                        
                                                                                
  PROCEDURE BACKUPVALIDATE( ARCHLOG_FAILOVER OUT BOOLEAN,                       
                            NOCLEANUP        IN  BOOLEAN ) IS                   
    BEGIN                                                                       
        ICDSTART(19);                                                           
        KRBIBV(ARCHLOG_FAILOVER, NOCLEANUP);                                    
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END BACKUPVALIDATE;                                                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBSTA( STATE        OUT BINARY_INTEGER                           
                     ,SETID        OUT NUMBER                                   
                     ,STAMP        OUT NUMBER                                   
                     ,PIECENO      OUT BINARY_INTEGER                           
                     ,FILES        OUT BINARY_INTEGER                           
                     ,DATAFILES    OUT BOOLEAN                                  
                     ,INCREMENTAL  OUT BOOLEAN                                  
                     ,NOCHECKSUM   OUT BOOLEAN                                  
                     ,DEVICE       OUT BOOLEAN );                               
  PRAGMA INTERFACE (C, KRBIBSTA);                                               
                                                                                
                                                                                
  PROCEDURE BACKUPSTATUS( STATE        OUT BINARY_INTEGER                       
                         ,SETID        OUT NUMBER                               
                         ,STAMP        OUT NUMBER                               
                         ,PIECENO      OUT BINARY_INTEGER                       
                         ,FILES        OUT BINARY_INTEGER                       
                         ,DATAFILES    OUT BOOLEAN                              
                         ,INCREMENTAL  OUT BOOLEAN                              
                         ,NOCHECKSUM   OUT BOOLEAN                              
                         ,DEVICE       OUT BOOLEAN ) IS                         
    BEGIN                                                                       
        ICDSTART(20);                                                           
        KRBIBSTA(STATE ,SETID ,STAMP ,PIECENO ,FILES ,DATAFILES ,INCREMENTAL    
                 ,NOCHECKSUM ,DEVICE);                                          
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBCLE;                                                           
  PRAGMA INTERFACE (C, KRBIBCLE);                                               
                                                                                
                                                                                
  PROCEDURE BACKUPCANCEL IS                                                     
    BEGIN                                                                       
        ICDSTART(21);                                                           
        KRBIBCLE;                                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICBBP( BPNAME        IN   VARCHAR2                               
                     ,FNAME         IN   VARCHAR2                               
                     ,HANDLE        OUT  VARCHAR2                               
                     ,COMMENT       OUT  VARCHAR2                               
                     ,MEDIA         OUT  VARCHAR2                               
                     ,CONCUR        OUT  BOOLEAN                                
                     ,RECID         OUT  NUMBER                                 
                     ,STAMP         OUT  NUMBER                                 
                     ,TAG           IN   VARCHAR2       DEFAULT NULL            
                     ,PARAMS        IN   VARCHAR2       DEFAULT NULL            
                     ,MEDIA_POOL    IN   BINARY_INTEGER DEFAULT 0               
                     ,REUSE         IN   BOOLEAN        DEFAULT FALSE           
                     ,CHECK_LOGICAL IN   BOOLEAN                                
                     ,COPYNO        IN   BINARY_INTEGER                         
                     ,DEFFMT        IN   BINARY_INTEGER                         
                     ,COPY_RECID    IN   NUMBER                                 
                     ,COPY_STAMP    IN   NUMBER                                 
                     ,NPIECES       IN   BINARY_INTEGER                         
                     ,RESTORE       IN   BOOLEAN                                
                     ,DEST          IN   BINARY_INTEGER);                       
  PRAGMA INTERFACE (C, KRBICBBP);                                               
                                                                                
                                                                                
  PROCEDURE BACKUPBACKUPPIECE( BPNAME     IN   VARCHAR2                         
                              ,FNAME      IN   VARCHAR2                         
                              ,HANDLE     OUT  VARCHAR2                         
                              ,COMMENT    OUT  VARCHAR2                         
                              ,MEDIA      OUT  VARCHAR2                         
                              ,CONCUR     OUT  BOOLEAN                          
                              ,RECID      OUT  NUMBER                           
                              ,STAMP      OUT  NUMBER                           
                              ,TAG        IN   VARCHAR2       DEFAULT NULL      
                              ,PARAMS     IN   VARCHAR2       DEFAULT NULL      
                              ,MEDIA_POOL IN   BINARY_INTEGER DEFAULT 0         
                              ,REUSE      IN   BOOLEAN        DEFAULT FALSE) IS 
    BEGIN                                                                       
        BACKUPBACKUPPIECE(BPNAME, FNAME, HANDLE, COMMENT, MEDIA, CONCUR,        
                          RECID, STAMP, TAG, PARAMS, MEDIA_POOL, REUSE,         
                          FALSE, 0);                                            
    END;                                                                        
                                                                                
  PROCEDURE BACKUPBACKUPPIECE( BPNAME          IN  VARCHAR2                     
                              ,FNAME           IN  VARCHAR2                     
                              ,HANDLE          OUT VARCHAR2                     
                              ,COMMENT         OUT VARCHAR2                     
                              ,MEDIA           OUT VARCHAR2                     
                              ,CONCUR          OUT BOOLEAN                      
                              ,RECID           OUT NUMBER                       
                              ,STAMP           OUT NUMBER                       
                              ,TAG             IN  VARCHAR2       DEFAULT NULL  
                              ,PARAMS          IN  VARCHAR2       DEFAULT NULL  
                              ,MEDIA_POOL      IN  BINARY_INTEGER DEFAULT 0     
                              ,REUSE           IN  BOOLEAN        DEFAULT FALSE 
                              ,CHECK_LOGICAL   IN  BOOLEAN) IS                  
    BEGIN                                                                       
        BACKUPBACKUPPIECE(BPNAME, FNAME, HANDLE, COMMENT, MEDIA, CONCUR,        
                          RECID, STAMP, TAG, PARAMS, MEDIA_POOL, REUSE,         
                          CHECK_LOGICAL, 0);                                    
    END;                                                                        
                                                                                
  PROCEDURE BACKUPBACKUPPIECE( BPNAME          IN  VARCHAR2                     
                              ,FNAME           IN  VARCHAR2                     
                              ,HANDLE          OUT VARCHAR2                     
                              ,COMMENT         OUT VARCHAR2                     
                              ,MEDIA           OUT VARCHAR2                     
                              ,CONCUR          OUT BOOLEAN                      
                              ,RECID           OUT NUMBER                       
                              ,STAMP           OUT NUMBER                       
                              ,TAG             IN  VARCHAR2       DEFAULT NULL  
                              ,PARAMS          IN  VARCHAR2       DEFAULT NULL  
                              ,MEDIA_POOL      IN  BINARY_INTEGER DEFAULT 0     
                              ,REUSE           IN  BOOLEAN        DEFAULT FALSE 
                              ,CHECK_LOGICAL   IN  BOOLEAN                      
                              ,COPYNO          IN  BINARY_INTEGER ) IS          
    BEGIN                                                                       
        BACKUPBACKUPPIECE(BPNAME, FNAME, HANDLE, COMMENT, MEDIA, CONCUR,        
                          RECID, STAMP, TAG, PARAMS, MEDIA_POOL, REUSE,         
                          CHECK_LOGICAL, COPYNO, 0, 0, 0, 0);                   
    END;                                                                        
                                                                                
  PROCEDURE BACKUPBACKUPPIECE( BPNAME          IN  VARCHAR2                     
                              ,FNAME           IN  VARCHAR2                     
                              ,HANDLE          OUT VARCHAR2                     
                              ,COMMENT         OUT VARCHAR2                     
                              ,MEDIA           OUT VARCHAR2                     
                              ,CONCUR          OUT BOOLEAN                      
                              ,RECID           OUT NUMBER                       
                              ,STAMP           OUT NUMBER                       
                              ,TAG             IN  VARCHAR2       DEFAULT NULL  
                              ,PARAMS          IN  VARCHAR2       DEFAULT NULL  
                              ,MEDIA_POOL      IN  BINARY_INTEGER DEFAULT 0     
                              ,REUSE           IN  BOOLEAN        DEFAULT FALSE 
                              ,CHECK_LOGICAL   IN  BOOLEAN                      
                              ,COPYNO          IN  BINARY_INTEGER               
                              ,DEFFMT          IN  BINARY_INTEGER               
                              ,COPY_RECID      IN  NUMBER                       
                              ,COPY_STAMP      IN  NUMBER                       
                              ,NPIECES         IN  BINARY_INTEGER) IS           
    BEGIN                                                                       
        BACKUPBACKUPPIECE(BPNAME, FNAME, HANDLE, COMMENT, MEDIA, CONCUR,        
                          RECID, STAMP, TAG, PARAMS, MEDIA_POOL, REUSE,         
                          CHECK_LOGICAL, COPYNO, DEFFMT, COPY_RECID,            
                          COPY_STAMP, NPIECES, 0);                              
    END;                                                                        
                                                                                
  PROCEDURE BACKUPBACKUPPIECE( BPNAME          IN  VARCHAR2                     
                              ,FNAME           IN  VARCHAR2                     
                              ,HANDLE          OUT VARCHAR2                     
                              ,COMMENT         OUT VARCHAR2                     
                              ,MEDIA           OUT VARCHAR2                     
                              ,CONCUR          OUT BOOLEAN                      
                              ,RECID           OUT NUMBER                       
                              ,STAMP           OUT NUMBER                       
                              ,TAG             IN  VARCHAR2       DEFAULT NULL  
                              ,PARAMS          IN  VARCHAR2       DEFAULT NULL  
                              ,MEDIA_POOL      IN  BINARY_INTEGER DEFAULT 0     
                              ,REUSE           IN  BOOLEAN        DEFAULT FALSE 
                              ,CHECK_LOGICAL   IN  BOOLEAN                      
                              ,COPYNO          IN  BINARY_INTEGER               
                              ,DEFFMT          IN  BINARY_INTEGER               
                              ,COPY_RECID      IN  NUMBER                       
                              ,COPY_STAMP      IN  NUMBER                       
                              ,NPIECES         IN  BINARY_INTEGER               
                              ,DEST            IN  BINARY_INTEGER) IS           
        INPUT_BPNAME  VARCHAR2(513) NOT NULL := ' ';                            
        INPUT_FNAME   VARCHAR2(513) NOT NULL := ' ';                            
    BEGIN                                                                       
        ICDSTART(22, CHKEVENTS=>TRUE);                                          
        INPUT_BPNAME := BPNAME;                                                 
        INPUT_FNAME := FNAME;                                                   
        KRBICBBP(INPUT_BPNAME, INPUT_FNAME, HANDLE, COMMENT, MEDIA, CONCUR,     
                 RECID, STAMP, TAG, PARAMS, MEDIA_POOL, REUSE,                  
                 CHECK_LOGICAL, COPYNO, DEFFMT, COPY_RECID, COPY_STAMP,         
                 NPIECES, FALSE, DEST);                                         
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE BACKUPPIECERESTORE(BPNAME         IN   VARCHAR2                     
                              ,FNAME          IN   VARCHAR2                     
                              ,HANDLE         OUT  VARCHAR2                     
                              ,RECID          OUT  NUMBER                       
                              ,STAMP          OUT  NUMBER                       
                              ,TAG            IN   VARCHAR2   DEFAULT NULL      
                              ,REUSE          IN   BOOLEAN    DEFAULT FALSE     
                              ,CHECK_LOGICAL  IN   BOOLEAN) IS                  
        INPUT_BPNAME  VARCHAR2(513) NOT NULL := ' ';                            
        INPUT_FNAME   VARCHAR2(513) NOT NULL := ' ';                            
        COMMENT       VARCHAR2(80);                                             
        MEDIA         VARCHAR2(80);                                             
        CONCUR        BOOLEAN;                                                  
    BEGIN                                                                       
        ICDSTART(167, CHKEVENTS=>TRUE);                                         
        INPUT_BPNAME := BPNAME;                                                 
        INPUT_FNAME := FNAME;                                                   
        KRBICBBP(BPNAME        => INPUT_BPNAME                                  
                ,FNAME         => INPUT_FNAME                                   
                ,HANDLE        => HANDLE                                        
                ,COMMENT       => COMMENT                                       
                ,MEDIA         => MEDIA                                         
                ,CONCUR        => CONCUR                                        
                ,RECID         => RECID                                         
                ,STAMP         => STAMP                                         
                ,TAG           => TAG                                           
                ,PARAMS        => NULL                                          
                ,MEDIA_POOL    => 0                                             
                ,REUSE         => REUSE                                         
                ,CHECK_LOGICAL => CHECK_LOGICAL                                 
                ,COPYNO        => 0                                             
                ,DEFFMT        => 0                                             
                ,COPY_RECID    => 0                                             
                ,COPY_STAMP    => 0                                             
                ,NPIECES       => 0                                             
                ,RESTORE       => TRUE                                          
                ,DEST          => 0);                                           
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICDF( DFNUMBER      IN   BINARY_INTEGER                          
                    ,FNAME         IN   VARCHAR2                                
                    ,FULL_NAME     OUT  VARCHAR2                                
                    ,RECID         OUT  NUMBER                                  
                    ,STAMP         OUT  NUMBER                                  
                    ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0                
                    ,TAG           IN   VARCHAR2       DEFAULT NULL             
                    ,NOCHECKSUM    IN   BOOLEAN        DEFAULT FALSE            
                    ,ISBACKUP      IN   BOOLEAN        DEFAULT FALSE            
                    ,CHECK_LOGICAL IN   BOOLEAN                                 
                    ,KEEP_OPTIONS  IN   BINARY_INTEGER                          
                    ,KEEP_UNTIL    IN   NUMBER);                                
  PRAGMA INTERFACE (C, KRBICDF);                                                
                                                                                
  PROCEDURE COPYDATAFILE( DFNUMBER      IN   BINARY_INTEGER                     
                         ,FNAME         IN   VARCHAR2                           
                         ,FULL_NAME     OUT  VARCHAR2                           
                         ,RECID         OUT  NUMBER                             
                         ,STAMP         OUT  NUMBER                             
                         ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0           
                         ,TAG           IN   VARCHAR2       DEFAULT NULL        
                         ,NOCHECKSUM    IN   BOOLEAN        DEFAULT FALSE       
                         ,ISBACKUP      IN   BOOLEAN        DEFAULT FALSE) IS   
    BEGIN                                                                       
        COPYDATAFILE(DFNUMBER, FNAME, FULL_NAME, RECID, STAMP,                  
                     MAX_CORRUPT, TAG, NOCHECKSUM, ISBACKUP, FALSE, 0, 0);      
    END;                                                                        
                                                                                
  PROCEDURE COPYDATAFILE( DFNUMBER      IN   BINARY_INTEGER                     
                         ,FNAME         IN   VARCHAR2                           
                         ,FULL_NAME     OUT  VARCHAR2                           
                         ,RECID         OUT  NUMBER                             
                         ,STAMP         OUT  NUMBER                             
                         ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0           
                         ,TAG           IN   VARCHAR2       DEFAULT NULL        
                         ,NOCHECKSUM    IN   BOOLEAN        DEFAULT FALSE       
                         ,ISBACKUP      IN   BOOLEAN        DEFAULT FALSE       
                         ,CHECK_LOGICAL IN   BOOLEAN) IS                        
    BEGIN                                                                       
        COPYDATAFILE(DFNUMBER, FNAME, FULL_NAME, RECID, STAMP,                  
                     MAX_CORRUPT, TAG, NOCHECKSUM, ISBACKUP,                    
                     CHECK_LOGICAL, 0, 0);                                      
    END;                                                                        
                                                                                
  PROCEDURE COPYDATAFILE( DFNUMBER      IN   BINARY_INTEGER                     
                         ,FNAME         IN   VARCHAR2                           
                         ,FULL_NAME     OUT  VARCHAR2                           
                         ,RECID         OUT  NUMBER                             
                         ,STAMP         OUT  NUMBER                             
                         ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0           
                         ,TAG           IN   VARCHAR2       DEFAULT NULL        
                         ,NOCHECKSUM    IN   BOOLEAN        DEFAULT FALSE       
                         ,ISBACKUP      IN   BOOLEAN        DEFAULT FALSE       
                         ,CHECK_LOGICAL IN   BOOLEAN        DEFAULT FALSE       
                         ,KEEP_OPTIONS  IN   BINARY_INTEGER                     
                         ,KEEP_UNTIL    IN   NUMBER) IS                         
        IDFNUMBER       BINARY_INTEGER  NOT NULL := 0;                          
        IFNAME          VARCHAR2(513)   NOT NULL := ' ';                        
        IKEEPOPT        BINARY_INTEGER  NOT NULL := 0;                          
        IKEEPUNTIL      NUMBER          NOT NULL := 0;                          
    BEGIN                                                                       
        ICDSTART(23, CHKEVENTS=>TRUE);                                          
        IDFNUMBER := DFNUMBER;                                                  
        IFNAME := FNAME;                                                        
        IKEEPOPT := KEEP_OPTIONS;                                               
        IKEEPUNTIL := KEEP_UNTIL;                                               
        SETMODULE('copy datafile');                                             
        KRBICDF(DFNUMBER, FNAME, FULL_NAME, RECID, STAMP,                       
                MAX_CORRUPT, TAG, NOCHECKSUM, ISBACKUP, CHECK_LOGICAL,          
                KEEP_OPTIONS, KEEP_UNTIL);                                      
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICDCP( COPY_RECID    IN   NUMBER                                 
                     ,COPY_STAMP    IN   NUMBER                                 
                     ,FULL_NAME     OUT  VARCHAR2                               
                     ,RECID         OUT  NUMBER                                 
                     ,STAMP         OUT  NUMBER                                 
                     ,FNAME         IN   VARCHAR2        DEFAULT NULL           
                     ,MAX_CORRUPT   IN   BINARY_INTEGER  DEFAULT 0              
                     ,TAG           IN   VARCHAR2        DEFAULT NULL           
                     ,NOCHECKSUM    IN   BOOLEAN         DEFAULT FALSE          
                     ,ISBACKUP      IN   BOOLEAN         DEFAULT FALSE          
                     ,CHECK_LOGICAL IN   BOOLEAN                                
                     ,KEEP_OPTIONS  IN   BINARY_INTEGER                         
                     ,KEEP_UNTIL    IN   NUMBER);                               
  PRAGMA INTERFACE (C, KRBICDCP);                                               
                                                                                
                                                                                
  PROCEDURE COPYDATAFILECOPY( COPY_RECID   IN   NUMBER                          
                             ,COPY_STAMP   IN   NUMBER                          
                             ,FULL_NAME    OUT  VARCHAR2                        
                             ,RECID        OUT  NUMBER                          
                             ,STAMP        OUT  NUMBER                          
                             ,FNAME        IN   VARCHAR2       DEFAULT NULL     
                             ,MAX_CORRUPT  IN   BINARY_INTEGER DEFAULT 0        
                             ,TAG          IN   VARCHAR2       DEFAULT NULL     
                             ,NOCHECKSUM   IN   BOOLEAN        DEFAULT FALSE    
                             ,ISBACKUP     IN   BOOLEAN        DEFAULT FALSE)   
  IS                                                                            
    BEGIN                                                                       
        COPYDATAFILECOPY(COPY_RECID, COPY_STAMP, FULL_NAME, RECID, STAMP,       
                         FNAME, MAX_CORRUPT, TAG, NOCHECKSUM, ISBACKUP, FALSE,  
                         0, 0);                                                 
    END;                                                                        
                                                                                
  PROCEDURE COPYDATAFILECOPY( COPY_RECID    IN   NUMBER                         
                             ,COPY_STAMP    IN   NUMBER                         
                             ,FULL_NAME     OUT  VARCHAR2                       
                             ,RECID         OUT  NUMBER                         
                             ,STAMP         OUT  NUMBER                         
                             ,FNAME         IN   VARCHAR2       DEFAULT NULL    
                             ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0       
                             ,TAG           IN   VARCHAR2       DEFAULT NULL    
                             ,NOCHECKSUM    IN   BOOLEAN        DEFAULT FALSE   
                             ,ISBACKUP      IN   BOOLEAN        DEFAULT FALSE   
                             ,CHECK_LOGICAL IN   BOOLEAN) IS                    
    BEGIN                                                                       
        COPYDATAFILECOPY(COPY_RECID, COPY_STAMP, FULL_NAME, RECID, STAMP,       
                         FNAME, MAX_CORRUPT, TAG, NOCHECKSUM, ISBACKUP,         
                         CHECK_LOGICAL, 0, 0);                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE COPYDATAFILECOPY( COPY_RECID    IN   NUMBER                         
                             ,COPY_STAMP    IN   NUMBER                         
                             ,FULL_NAME     OUT  VARCHAR2                       
                             ,RECID         OUT  NUMBER                         
                             ,STAMP         OUT  NUMBER                         
                             ,FNAME         IN   VARCHAR2       DEFAULT NULL    
                             ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0       
                             ,TAG           IN   VARCHAR2       DEFAULT NULL    
                             ,NOCHECKSUM    IN   BOOLEAN        DEFAULT FALSE   
                             ,ISBACKUP      IN   BOOLEAN        DEFAULT FALSE   
                             ,CHECK_LOGICAL IN   BOOLEAN        DEFAULT FALSE   
                             ,KEEP_OPTIONS  IN   BINARY_INTEGER                 
                             ,KEEP_UNTIL    IN   NUMBER) IS                     
        INPUT_RECID  NUMBER     NOT NULL := 0;                                  
        INPUT_STAMP  NUMBER     NOT NULL := 0;                                  
        IKEEPOPT        BINARY_INTEGER  NOT NULL := 0;                          
        IKEEPUNTIL      NUMBER          NOT NULL := 0;                          
    BEGIN                                                                       
        ICDSTART(24, CHKEVENTS=>TRUE);                                          
        INPUT_RECID := COPY_RECID;                                              
        INPUT_STAMP := COPY_STAMP;                                              
        IKEEPOPT := KEEP_OPTIONS;                                               
        IKEEPUNTIL := KEEP_UNTIL;                                               
        SETMODULE('copy datafilecopy');                                         
        KRBICDCP(INPUT_RECID, INPUT_STAMP, FULL_NAME, RECID, STAMP,             
                 FNAME, MAX_CORRUPT, TAG, NOCHECKSUM, ISBACKUP, CHECK_LOGICAL,  
                 KEEP_OPTIONS, KEEP_UNTIL);                                     
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBICRL( ARCH_RECID  IN   NUMBER                                    
                    ,ARCH_STAMP  IN   NUMBER                                    
                    ,FNAME       IN   VARCHAR2                                  
                    ,FULL_NAME   OUT  VARCHAR2                                  
                    ,RECID       OUT  NUMBER                                    
                    ,STAMP       OUT  NUMBER                                    
                    ,NOCHECKSUM  IN   BOOLEAN  DEFAULT FALSE );                 
  PRAGMA INTERFACE (C, KRBICRL);                                                
                                                                                
                                                                                
  PROCEDURE COPYARCHIVEDLOG( ARCH_RECID  IN   NUMBER                            
                        ,ARCH_STAMP  IN   NUMBER                                
                        ,FNAME       IN   VARCHAR2                              
                        ,FULL_NAME   OUT  VARCHAR2                              
                        ,RECID       OUT  NUMBER                                
                        ,STAMP       OUT  NUMBER                                
                        ,NOCHECKSUM  IN   BOOLEAN  DEFAULT FALSE ) IS           
        INPUT_RECID  NUMBER     NOT NULL := 0;                                  
        INPUT_STAMP  NUMBER     NOT NULL := 0;                                  
        INPUT_FNAME  VARCHAR2(513) NOT NULL := ' ';                             
    BEGIN                                                                       
        ICDSTART(25, CHKEVENTS=>TRUE);                                          
        INPUT_RECID := ARCH_RECID;                                              
        INPUT_STAMP := ARCH_STAMP;                                              
        INPUT_FNAME := FNAME;                                                   
        SETMODULE('copy archivelogs');                                          
        KRBICRL(INPUT_RECID, INPUT_STAMP, INPUT_FNAME, FULL_NAME,               
                RECID, STAMP, NOCHECKSUM);                                      
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBICCF( SRC_NAME     IN   VARCHAR2                                 
                    ,DEST_NAME    IN   VARCHAR2                                 
                    ,RECID        OUT  NUMBER                                   
                    ,STAMP        OUT  NUMBER                                   
                    ,FULL_NAME    OUT  VARCHAR2                                 
                    ,KEEP_OPTIONS IN   BINARY_INTEGER                           
                    ,KEEP_UNTIL   IN   NUMBER);                                 
  PRAGMA INTERFACE (C, KRBICCF);                                                
                                                                                
                                                                                
  PROCEDURE COPYCONTROLFILE( SRC_NAME   IN   VARCHAR2                           
                            ,DEST_NAME  IN   VARCHAR2                           
                            ,RECID      OUT  NUMBER                             
                            ,STAMP      OUT  NUMBER                             
                            ,FULL_NAME  OUT  VARCHAR2) IS                       
    BEGIN                                                                       
       COPYCONTROLFILE(SRC_NAME, DEST_NAME, RECID, STAMP, FULL_NAME,            
                       0, 0);                                                   
    END;                                                                        
                                                                                
  PROCEDURE COPYCONTROLFILE( SRC_NAME     IN   VARCHAR2                         
                            ,DEST_NAME    IN   VARCHAR2                         
                            ,RECID        OUT  NUMBER                           
                            ,STAMP        OUT  NUMBER                           
                            ,FULL_NAME    OUT  VARCHAR2                         
                            ,KEEP_OPTIONS IN   BINARY_INTEGER                   
                            ,KEEP_UNTIL   IN   NUMBER) IS                       
    BEGIN                                                                       
        ICDSTART(26, CHKEVENTS=>TRUE);                                          
        KRBICCF(SRC_NAME, DEST_NAME, RECID, STAMP, FULL_NAME,                   
                 KEEP_OPTIONS, KEEP_UNTIL);                                     
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIIF(  TYPE       IN   BINARY_INTEGER                             
                    ,FNAME      IN   VARCHAR2                                   
                    ,FULL_NAME  OUT  VARCHAR2                                   
                    ,RECID      OUT  NUMBER                                     
                    ,STAMP      OUT  NUMBER                                     
                    ,TAG        IN   VARCHAR2  DEFAULT NULL                     
                    ,ISBACKUP   IN   BOOLEAN  DEFAULT FALSE                     
                    ,CHANGE_RDI IN   BOOLEAN  DEFAULT TRUE);                    
  PRAGMA INTERFACE (C, KRBIIF);                                                 
                                                                                
                                                                                
  PROCEDURE INSPECTDATAFILECOPY( FNAME      IN   VARCHAR2                       
                            ,FULL_NAME  OUT  VARCHAR2                           
                            ,RECID      OUT  NUMBER                             
                            ,STAMP      OUT  NUMBER                             
                            ,TAG        IN   VARCHAR2  DEFAULT NULL             
                            ,ISBACKUP   IN   BOOLEAN  DEFAULT FALSE) IS         
    BEGIN                                                                       
        INSPECTDATAFILECOPY(FNAME, FULL_NAME, RECID, STAMP, TAG,                
                            ISBACKUP, TRUE);                                    
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE INSPECTDATAFILECOPY( FNAME      IN   VARCHAR2                       
                            ,FULL_NAME  OUT  VARCHAR2                           
                            ,RECID      OUT  NUMBER                             
                            ,STAMP      OUT  NUMBER                             
                            ,TAG        IN   VARCHAR2  DEFAULT NULL             
                            ,ISBACKUP   IN   BOOLEAN  DEFAULT FALSE             
                            ,CHANGE_RDI IN   BOOLEAN) IS                        
        INPUT_FNAME  VARCHAR2(513) NOT NULL := ' ';                             
    BEGIN                                                                       
        ICDSTART(27);                                                           
        INPUT_FNAME := FNAME;                                                   
        KRBIIF(IF_DATAFILE,INPUT_FNAME, FULL_NAME, RECID, STAMP, TAG,           
               ISBACKUP, CHANGE_RDI);                                           
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE INSPECTCONTROLFILE(FNAME      IN   VARCHAR2                         
                               ,FULL_NAME  OUT  VARCHAR2                        
                               ,RECID      OUT  NUMBER                          
                               ,STAMP      OUT  NUMBER ) IS                     
        INPUT_FNAME  VARCHAR2(513) NOT NULL := ' ';                             
    BEGIN                                                                       
        ICDSTART(28, CHKEVENTS=>TRUE);                                          
        INPUT_FNAME := FNAME;                                                   
        KRBIIF(IF_CONTROLFILE, INPUT_FNAME, FULL_NAME, RECID, STAMP);           
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE INSPECTARCHIVEDLOG( FNAME      IN   VARCHAR2                        
                           ,FULL_NAME  OUT  VARCHAR2                            
                           ,RECID      OUT  NUMBER                              
                           ,STAMP      OUT  NUMBER ) IS                         
    BEGIN                                                                       
        INSPECTARCHIVEDLOG(FNAME, FULL_NAME, RECID, STAMP, TRUE);               
    END;                                                                        
  PROCEDURE INSPECTARCHIVEDLOG( FNAME      IN   VARCHAR2                        
                           ,FULL_NAME  OUT  VARCHAR2                            
                           ,RECID      OUT  NUMBER                              
                           ,STAMP      OUT  NUMBER                              
                           ,CHANGE_RDI IN BOOLEAN ) IS                          
        INPUT_FNAME  VARCHAR2(513) NOT NULL := ' ';                             
    BEGIN                                                                       
        ICDSTART(29, CHKEVENTS=>TRUE);                                          
        INPUT_FNAME := FNAME;                                                   
        KRBIIF(IF_ARCHIVEDLOG, INPUT_FNAME, FULL_NAME, RECID, STAMP,            
               CHANGE_RDI=>CHANGE_RDI);                                         
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE INSPECTBACKUPPIECE( HANDLE      IN   VARCHAR2                       
                               ,FULL_HANDLE OUT  VARCHAR2                       
                               ,RECID       OUT  NUMBER                         
                               ,STAMP       OUT  NUMBER ) IS                    
        INPUT_HANDLE  VARCHAR2(513) NOT NULL := ' ';                            
    BEGIN                                                                       
        ICDSTART(30, CHKEVENTS=>TRUE);                                          
        INPUT_HANDLE := HANDLE;                                                 
        KRBIIF(IF_BACKUPPIECE, INPUT_HANDLE, FULL_HANDLE, RECID, STAMP);        
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRSDF( TYPE         IN BINARY_INTEGER                            
                     ,DESTINATION  IN VARCHAR2  DEFAULT NULL                    
                     ,CHECK_LOGICAL IN BOOLEAN                                  
                     ,CLEANUP       IN BOOLEAN);                                
                                                                                
  PRAGMA INTERFACE (C, KRBIRSDF);                                               
                                                                                
                                                                                
  PROCEDURE RESTORESETDATAFILE IS                                               
    BEGIN                                                                       
        RESTORESETDATAFILE( CHECK_LOGICAL => FALSE                              
                           ,CLEANUP       => TRUE);                             
    END;                                                                        
                                                                                
  PROCEDURE RESTORESETDATAFILE(CHECK_LOGICAL IN BOOLEAN) IS                     
    BEGIN                                                                       
        RESTORESETDATAFILE( CHECK_LOGICAL => CHECK_LOGICAL                      
                           ,CLEANUP       => TRUE);                             
    END;                                                                        
                                                                                
  PROCEDURE RESTORESETDATAFILE( CHECK_LOGICAL IN BOOLEAN                        
                               ,CLEANUP       IN BOOLEAN) IS                    
    BEGIN                                                                       
        ICDSTART(31, CHKEVENTS=>TRUE);                                          
        SETMODULE('restore full datafile');                                     
        KRBIRSDF( TYPE          => RCIP_DATAFILE_RESTORE                        
                 ,CHECK_LOGICAL => CHECK_LOGICAL                                
                 ,CLEANUP       => CLEANUP);                                    
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE APPLYSETDATAFILE IS                                                 
    BEGIN                                                                       
        APPLYSETDATAFILE( CHECK_LOGICAL => FALSE                                
                         ,CLEANUP       => TRUE);                               
    END;                                                                        
                                                                                
  PROCEDURE APPLYSETDATAFILE(CHECK_LOGICAL IN BOOLEAN) IS                       
    BEGIN                                                                       
        APPLYSETDATAFILE( CHECK_LOGICAL => CHECK_LOGICAL                        
                         ,CLEANUP       => TRUE);                               
                                                                                
    END;                                                                        
                                                                                
  PROCEDURE APPLYSETDATAFILE( CHECK_LOGICAL IN BOOLEAN                          
                             ,CLEANUP       IN BOOLEAN) IS                      
    BEGIN                                                                       
        ICDSTART(32, CHKEVENTS=>TRUE);                                          
        SETMODULE('restore incr datafile');                                     
        KRBIRSDF( TYPE          => RCIP_DATAFILE_APPLY                          
                 ,CHECK_LOGICAL => CHECK_LOGICAL                                
                 ,CLEANUP       => CLEANUP);                                    
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE RESTORESETARCHIVEDLOG( DESTINATION  IN VARCHAR2  DEFAULT NULL ) IS  
    BEGIN                                                                       
       RESTORESETARCHIVEDLOG(DESTINATION, TRUE);                                
    END;                                                                        
                                                                                
  PROCEDURE RESTORESETARCHIVEDLOG( DESTINATION  IN VARCHAR2  DEFAULT NULL       
                                  ,CLEANUP      IN BOOLEAN ) IS                 
    BEGIN                                                                       
        ICDSTART(33);                                                           
        SETMODULE('restore archivelog');                                        
        KRBIRSDF( TYPE          => RCIP_ARCHIVELOG_RESTORE                      
                 ,DESTINATION   => DESTINATION                                  
                 ,CHECK_LOGICAL => FALSE                                        
                 ,CLEANUP       => CLEANUP);                                    
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRCFT( CFNAME IN VARCHAR2                                        
                     ,ISSTBY IN BOOLEAN);                                       
  PRAGMA INTERFACE (C, KRBIRCFT);                                               
                                                                                
  PROCEDURE RESTORECONTROLFILETO(CFNAME IN VARCHAR2) IS                         
    BEGIN                                                                       
        RESTORECONTROLFILETO(CFNAME, FALSE);                                    
    END;                                                                        
                                                                                
  PROCEDURE RESTORECONTROLFILETO( CFNAME IN VARCHAR2                            
                                 ,ISSTBY IN BOOLEAN) IS                         
    BEGIN                                                                       
        ICDSTART(34);                                                           
        KRBIRCFT(CFNAME, ISSTBY);                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRDFT( DFNUMBER    IN BINARY_INTEGER                             
                     ,TONAME      IN VARCHAR2       DEFAULT NULL                
                     ,MAX_CORRUPT IN BINARY_INTEGER                             
                     ,TSNAME      IN VARCHAR2);                                 
  PRAGMA INTERFACE (C, KRBIRDFT);                                               
                                                                                
                                                                                
  PROCEDURE RESTOREDATAFILETO( DFNUMBER  IN  BINARY_INTEGER                     
                              ,TONAME    IN  VARCHAR2       DEFAULT NULL) IS    
    BEGIN                                                                       
        RESTOREDATAFILETO(DFNUMBER, TONAME, 0);                                 
    END;                                                                        
                                                                                
  PROCEDURE RESTOREDATAFILETO( DFNUMBER    IN  BINARY_INTEGER                   
                              ,TONAME      IN  VARCHAR2       DEFAULT NULL      
                              ,MAX_CORRUPT IN BINARY_INTEGER) IS                
        INPUT_DFNUMBER  BINARY_INTEGER NOT NULL := 0;                           
    BEGIN                                                                       
        RESTOREDATAFILETO(DFNUMBER, TONAME, 0, 'UNKNOWN');                      
    END;                                                                        
                                                                                
  PROCEDURE RESTOREDATAFILETO( DFNUMBER    IN BINARY_INTEGER                    
                              ,TONAME      IN VARCHAR2       DEFAULT NULL       
                              ,MAX_CORRUPT IN BINARY_INTEGER                    
                              ,TSNAME      IN VARCHAR2) IS                      
        INPUT_DFNUMBER  BINARY_INTEGER NOT NULL := 0;                           
    BEGIN                                                                       
        ICDSTART(35);                                                           
        INPUT_DFNUMBER := DFNUMBER;                                             
        KRBIRDFT(INPUT_DFNUMBER, TONAME, MAX_CORRUPT, TSNAME);                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBIADFT( DFNUMBER        IN  BINARY_INTEGER                        
                     ,TONAME          IN  VARCHAR2       DEFAULT NULL           
                     ,FUZZINESS_HINT  IN  NUMBER         DEFAULT 0              
                     ,MAX_CORRUPT     IN  BINARY_INTEGER                        
                     ,ISLEVEL0        IN  BINARY_INTEGER                        
                     ,RECID           IN  NUMBER                                
                     ,STAMP           IN  NUMBER);                              
  PRAGMA INTERFACE (C, KRBIADFT);                                               
                                                                                
                                                                                
  PROCEDURE APPLYDATAFILETO( DFNUMBER        IN  BINARY_INTEGER                 
                            ,TONAME          IN  VARCHAR2       DEFAULT NULL    
                            ,FUZZINESS_HINT  IN  NUMBER         DEFAULT 0) IS   
    BEGIN                                                                       
        APPLYDATAFILETO(DFNUMBER, TONAME, FUZZINESS_HINT, 0);                   
    END;                                                                        
                                                                                
  PROCEDURE APPLYDATAFILETO( DFNUMBER        IN  BINARY_INTEGER                 
                            ,TONAME          IN  VARCHAR2       DEFAULT NULL    
                            ,FUZZINESS_HINT  IN  NUMBER         DEFAULT 0       
                            ,MAX_CORRUPT     IN  BINARY_INTEGER) IS             
    BEGIN                                                                       
        APPLYDATAFILETO(DFNUMBER, TONAME, FUZZINESS_HINT, MAX_CORRUPT, 0,       
                        0, 0);                                                  
    END;                                                                        
                                                                                
  PROCEDURE APPLYDATAFILETO( DFNUMBER        IN  BINARY_INTEGER                 
                            ,TONAME          IN  VARCHAR2       DEFAULT NULL    
                            ,FUZZINESS_HINT  IN  NUMBER         DEFAULT 0       
                            ,MAX_CORRUPT     IN  BINARY_INTEGER                 
                            ,ISLEVEL0        IN  BINARY_INTEGER                 
                            ,RECID           IN  NUMBER                         
                            ,STAMP           IN  NUMBER) IS                     
        INPUT_DFNUMBER  BINARY_INTEGER NOT NULL := 0;                           
    BEGIN                                                                       
        ICDSTART(36);                                                           
        INPUT_DFNUMBER := DFNUMBER;                                             
        KRBIADFT(INPUT_DFNUMBER, TONAME, FUZZINESS_HINT, MAX_CORRUPT,           
                 ISLEVEL0, RECID, STAMP);                                       
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRRNG( LOW_CHANGE   IN NUMBER DEFAULT 0                          
                     ,HIGH_CHANGE  IN NUMBER DEFAULT 281474976710655 );         
  PRAGMA INTERFACE (C, KRBIRRNG);                                               
                                                                                
                                                                                
  PROCEDURE RESTOREARCHIVEDLOGRANGE( LOW_CHANGE   IN NUMBER DEFAULT 0           
                             ,HIGH_CHANGE  IN NUMBER DEFAULT 281474976710655 )  
  IS                                                                            
    BEGIN                                                                       
        ICDSTART(37);                                                           
        KRBIRRNG(LOW_CHANGE, HIGH_CHANGE);                                      
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBIRRL( THREAD    IN  BINARY_INTEGER                               
                    ,SEQUENCE  IN  NUMBER );                                    
  PRAGMA INTERFACE (C, KRBIRRL);                                                
                                                                                
                                                                                
  PROCEDURE RESTOREARCHIVEDLOG( THREAD    IN  BINARY_INTEGER                    
                           ,SEQUENCE  IN  NUMBER ) IS                           
        INPUT_THREAD  BINARY_INTEGER NOT NULL := 0;                             
        INPUT_SEQUENCE  NUMBER     NOT NULL := 0;                               
    BEGIN                                                                       
        ICDSTART(38);                                                           
        INPUT_THREAD := THREAD;                                                 
        INPUT_SEQUENCE := SEQUENCE;                                             
        KRBIRRL(INPUT_THREAD, INPUT_SEQUENCE);                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END RESTOREARCHIVEDLOG;                                                     
                                                                                
                                                                                
  PROCEDURE KRBIRVD;                                                            
  PRAGMA INTERFACE (C, KRBIRVD);                                                
                                                                                
                                                                                
  PROCEDURE RESTOREVALIDATE IS                                                  
    BEGIN                                                                       
        NULL;                                                                   
        ICDSTART(39);                                                           
        KRBIRVD;                                                                
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRBP( DONE      OUT  BOOLEAN                                     
                    ,PARAMS    IN   VARCHAR2  DEFAULT NULL                      
                    ,OUTHANDLE OUT VARCHAR2                                     
                    ,OUTTAG    OUT VARCHAR2                                     
                    ,FAILOVER  OUT  BOOLEAN );                                  
  PRAGMA INTERFACE (C, KRBIRBP);                                                
                                                                                
                                                                                
  PROCEDURE RESTOREBACKUPPIECE( DONE      OUT  BOOLEAN                          
                               ,PARAMS    IN   VARCHAR2  DEFAULT NULL           
                               ,OUTHANDLE OUT  VARCHAR2                         
                               ,OUTTAG    OUT  VARCHAR2                         
                               ,FAILOVER  OUT  BOOLEAN ) IS                     
    BEGIN                                                                       
        ICDSTART(40);                                                           
        KRBIRBP(DONE, PARAMS, OUTHANDLE, OUTTAG, FAILOVER);                     
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE APPLYBACKUPPIECE( HANDLE  IN   VARCHAR2                             
                             ,DONE    OUT  BOOLEAN                              
                             ,PARAMS  IN   VARCHAR2  DEFAULT NULL ) IS          
    BEGIN                                                                       
        RESTOREBACKUPPIECE(HANDLE, DONE, PARAMS, FALSE);                        
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBIAOR( CFNAME  IN  VARCHAR2,                                      
                     DFNAME  IN  VARCHAR2,                                      
                     BLKSIZE IN  NUMBER,                                        
                     RECID   IN  NUMBER,                                        
                     STAMP   IN  NUMBER,                                        
                     FNO     IN  BINARY_INTEGER,                                
                     DFRECID IN  NUMBER,                                        
                     DFSTAMP IN  NUMBER);                                       
  PRAGMA INTERFACE (C, KRBIAOR);                                                
                                                                                
  PROCEDURE APPLYOFFLINERANGE( CFNAME  IN  VARCHAR2 DEFAULT NULL,               
                               DFNAME  IN  VARCHAR2 DEFAULT NULL,               
                               BLKSIZE IN  NUMBER   DEFAULT NULL,               
                               RECID   IN  NUMBER   DEFAULT NULL,               
                               STAMP   IN  NUMBER   DEFAULT NULL,               
                               FNO     IN  BINARY_INTEGER) IS                   
    BEGIN                                                                       
       APPLYOFFLINERANGE(CFNAME, DFNAME, BLKSIZE, RECID, STAMP, FNO, 0, 0);     
    END;                                                                        
                                                                                
  PROCEDURE APPLYOFFLINERANGE( CFNAME  IN  VARCHAR2 DEFAULT NULL,               
                               DFNAME  IN  VARCHAR2 DEFAULT NULL,               
                               BLKSIZE IN  NUMBER   DEFAULT NULL,               
                               RECID   IN  NUMBER   DEFAULT NULL,               
                               STAMP   IN  NUMBER   DEFAULT NULL,               
                               FNO     IN  BINARY_INTEGER,                      
                               DFRECID IN  NUMBER,                              
                               DFSTAMP IN  NUMBER) IS                           
    BEGIN                                                                       
        ICDSTART(41);                                                           
        KRBIAOR(CFNAME, DFNAME, BLKSIZE, RECID, STAMP, FNO, DFRECID, DFSTAMP);  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRSTA( STATE        OUT BINARY_INTEGER                           
                     ,PIECENO      OUT BINARY_INTEGER                           
                     ,FILES        OUT BINARY_INTEGER                           
                     ,DATAFILES    OUT BOOLEAN                                  
                     ,INCREMENTAL  OUT BOOLEAN                                  
                     ,DEVICE       OUT BOOLEAN );                               
  PRAGMA INTERFACE (C, KRBIRSTA);                                               
                                                                                
                                                                                
  PROCEDURE RESTORESTATUS( STATE        OUT BINARY_INTEGER                      
                          ,PIECENO      OUT BINARY_INTEGER                      
                          ,FILES        OUT BINARY_INTEGER                      
                          ,DATAFILES    OUT BOOLEAN                             
                          ,INCREMENTAL  OUT BOOLEAN                             
                          ,DEVICE       OUT BOOLEAN ) IS                        
    BEGIN                                                                       
        ICDSTART(42);                                                           
        KRBIRSTA(STATE, PIECENO, FILES, DATAFILES, INCREMENTAL, DEVICE);        
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRCLE(CHECK_FILES IN BOOLEAN);                                   
  PRAGMA INTERFACE (C, KRBIRCLE);                                               
                                                                                
                                                                                
  PROCEDURE RESTORECANCEL IS                                                    
    BEGIN                                                                       
        RESTORECANCEL(FALSE);                                                   
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE RESTORECANCEL(CHECK_FILES IN BOOLEAN) IS                            
    BEGIN                                                                       
        ICDSTART(43);                                                           
        KRBIRCLE(CHECK_FILES);                                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICSSN( FNAME  IN  VARCHAR2 );                                    
  PRAGMA INTERFACE (C, KRBICSSN);                                               
                                                                                
                                                                                
  PROCEDURE CFILESETSNAPSHOTNAME( FNAME  IN  VARCHAR2 ) IS                      
    BEGIN                                                                       
        ICDSTART(44, CHKEVENTS=>TRUE);                                          
        KRBICSSN(FNAME);                                                        
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBICUS;                                                            
  PRAGMA INTERFACE (C, KRBICUS);                                                
                                                                                
                                                                                
  PROCEDURE CFILEUSESNAPSHOT IS                                                 
    BEGIN                                                                       
        ICDSTART(45, CHKEVENTS=>TRUE);                                          
        KRBICUS;                                                                
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBICUC;                                                            
  PRAGMA INTERFACE (C, KRBICUC);                                                
                                                                                
                                                                                
  PROCEDURE CFILEUSECURRENT IS                                                  
    BEGIN                                                                       
        ICDSTART(46, CHKEVENTS=>TRUE);                                          
        KRBICUC;                                                                
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE KRBICUP( FNAME  IN  VARCHAR2 );                                     
  PRAGMA INTERFACE (C, KRBICUP);                                                
                                                                                
                                                                                
  PROCEDURE CFILEUSECOPY( FNAME  IN  VARCHAR2 ) IS                              
        INPUT_FNAME  VARCHAR2(513) NOT NULL := ' ';                             
    BEGIN                                                                       
        ICDSTART(47, CHKEVENTS=>TRUE);                                          
        INPUT_FNAME := FNAME;                                                   
        KRBICUP(INPUT_FNAME);                                                   
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICRS( RECORD_TYPE     IN  BINARY_INTEGER                         
                    ,BEFORE_NUMRECS  OUT BINARY_INTEGER                         
                    ,AFTER_NUMRECS   OUT BINARY_INTEGER                         
                    ,DELTA_NUMRECS   IN  BINARY_INTEGER  DEFAULT 0 );           
  PRAGMA INTERFACE (C, KRBICRS);                                                
                                                                                
                                                                                
  PROCEDURE CFILERESIZESECTION( RECORD_TYPE     IN  BINARY_INTEGER              
                               ,BEFORE_NUMRECS  OUT BINARY_INTEGER              
                               ,AFTER_NUMRECS   OUT BINARY_INTEGER              
                               ,DELTA_NUMRECS   IN  BINARY_INTEGER  DEFAULT 0 ) 
  IS                                                                            
        INPUT_TYPE  BINARY_INTEGER  NOT NULL := 0;                              
    BEGIN                                                                       
        ICDSTART(48);                                                           
        INPUT_TYPE := RECORD_TYPE;                                              
        KRBICRS(INPUT_TYPE ,BEFORE_NUMRECS ,AFTER_NUMRECS ,DELTA_NUMRECS);      
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  FUNCTION KRBICSL(                                                             
                    NUM_CKPTPROG_RECS          IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_THREAD_RECS            IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_LOGFILE_RECS           IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_DATAFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_FILENAME_RECS          IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_TABLESPACE_RECS        IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_TEMPFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_RMANCONFIGURATION_RECS IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_LOGHISTORY_RECS        IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_OFFLINERANGE_RECS      IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_ARCHIVEDLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_BACKUPSET_RECS         IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_BACKUPPIECE_RECS       IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_BACKEDUPDFILE_RECS     IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_BACKEDUPLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_DFILECOPY_RECS         IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_BKDFCORRUPTION_RECS    IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_DFCOPYCORRUPTION_RECS  IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_DELETEDOBJECT_RECS     IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_PROXY_RECS             IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_RESERVED4_RECS         IN  BINARY_INTEGER  DEFAULT 0    
                   ,NUM_DB2_RECS               IN  BINARY_INTEGER               
                   ,NUM_INCARNATION_RECS       IN  BINARY_INTEGER               
                   ,NUM_FLASHBACK_RECS         IN  BINARY_INTEGER               
                   ,NUM_RAINFO_RECS            IN  BINARY_INTEGER               
                   ,NUM_INSTRSVT_RECS          IN  BINARY_INTEGER               
                   ,NUM_AGEDFILES_RECS         IN  BINARY_INTEGER               
                   ,NUM_RMANSTATUS_RECS        IN  BINARY_INTEGER               
                   ,NUM_THREADINST_RECS        IN  BINARY_INTEGER               
                   ,NUM_MTR_RECS               IN  BINARY_INTEGER               
                   ,NUM_DFH_RECS               IN  BINARY_INTEGER               
                   ,NUM_SDM_REC                IN  BINARY_INTEGER               
                   ,NUM_GRP_RECS               IN  BINARY_INTEGER               
                   ,NUM_RP_RECS                IN  BINARY_INTEGER               
                   ,NUM_BCR_RECS               IN  BINARY_INTEGER               
                   ,NUM_ACM_RECS               IN  BINARY_INTEGER               
                   ,NUM_RLR_RECS               IN  BINARY_INTEGER)              
    RETURN BINARY_INTEGER;                                                      
  PRAGMA INTERFACE (C, KRBICSL);                                                
                                                                                
  FUNCTION CFILECALCSIZELIST(                                                   
                  NUM_CKPTPROG_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_THREAD_RECS            IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGFILE_RECS           IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DATAFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_FILENAME_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TABLESPACE_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TEMPFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RMANCONFIGURATION_RECS IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGHISTORY_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_OFFLINERANGE_RECS      IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_ARCHIVEDLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPSET_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPPIECE_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPDFILE_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFILECOPY_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BKDFCORRUPTION_RECS    IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFCOPYCORRUPTION_RECS  IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DELETEDOBJECT_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_PROXY_RECS             IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RESERVED4_RECS         IN  BINARY_INTEGER  DEFAULT 0)     
    RETURN BINARY_INTEGER IS                                                    
    BEGIN                                                                       
       RETURN CFILECALCSIZELIST(NUM_CKPTPROG_RECS                               
                        ,NUM_THREAD_RECS                                        
                        ,NUM_LOGFILE_RECS                                       
                        ,NUM_DATAFILE_RECS                                      
                        ,NUM_FILENAME_RECS                                      
                        ,NUM_TABLESPACE_RECS                                    
                        ,NUM_TEMPFILE_RECS                                      
                        ,NUM_RMANCONFIGURATION_RECS                             
                        ,NUM_LOGHISTORY_RECS                                    
                        ,NUM_OFFLINERANGE_RECS                                  
                        ,NUM_ARCHIVEDLOG_RECS                                   
                        ,NUM_BACKUPSET_RECS                                     
                        ,NUM_BACKUPPIECE_RECS                                   
                        ,NUM_BACKEDUPDFILE_RECS                                 
                        ,NUM_BACKEDUPLOG_RECS                                   
                        ,NUM_DFILECOPY_RECS                                     
                        ,NUM_BKDFCORRUPTION_RECS                                
                        ,NUM_DFCOPYCORRUPTION_RECS                              
                        ,NUM_DELETEDOBJECT_RECS                                 
                        ,NUM_PROXY_RECS                                         
                        ,NUM_RESERVED4_RECS                                     
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        );                                                      
    END;                                                                        
                                                                                
  FUNCTION CFILECALCSIZELIST(                                                   
                  NUM_CKPTPROG_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_THREAD_RECS            IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGFILE_RECS           IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DATAFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_FILENAME_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TABLESPACE_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TEMPFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RMANCONFIGURATION_RECS IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGHISTORY_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_OFFLINERANGE_RECS      IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_ARCHIVEDLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPSET_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPPIECE_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPDFILE_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFILECOPY_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BKDFCORRUPTION_RECS    IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFCOPYCORRUPTION_RECS  IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DELETEDOBJECT_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_PROXY_RECS             IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RESERVED4_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DB2_RECS               IN  BINARY_INTEGER                 
                 ,NUM_INCARNATION_RECS       IN  BINARY_INTEGER)                
    RETURN BINARY_INTEGER IS                                                    
    BEGIN                                                                       
       RETURN CFILECALCSIZELIST(NUM_CKPTPROG_RECS                               
                        ,NUM_THREAD_RECS                                        
                        ,NUM_LOGFILE_RECS                                       
                        ,NUM_DATAFILE_RECS                                      
                        ,NUM_FILENAME_RECS                                      
                        ,NUM_TABLESPACE_RECS                                    
                        ,NUM_TEMPFILE_RECS                                      
                        ,NUM_RMANCONFIGURATION_RECS                             
                        ,NUM_LOGHISTORY_RECS                                    
                        ,NUM_OFFLINERANGE_RECS                                  
                        ,NUM_ARCHIVEDLOG_RECS                                   
                        ,NUM_BACKUPSET_RECS                                     
                        ,NUM_BACKUPPIECE_RECS                                   
                        ,NUM_BACKEDUPDFILE_RECS                                 
                        ,NUM_BACKEDUPLOG_RECS                                   
                        ,NUM_DFILECOPY_RECS                                     
                        ,NUM_BKDFCORRUPTION_RECS                                
                        ,NUM_DFCOPYCORRUPTION_RECS                              
                        ,NUM_DELETEDOBJECT_RECS                                 
                        ,NUM_PROXY_RECS                                         
                        ,NUM_RESERVED4_RECS                                     
                        ,NUM_DB2_RECS                                           
                        ,NUM_INCARNATION_RECS                                   
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        ,0                                                      
                        );                                                      
    END;                                                                        
                                                                                
  FUNCTION CFILECALCSIZELIST(                                                   
                  NUM_CKPTPROG_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_THREAD_RECS            IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGFILE_RECS           IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DATAFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_FILENAME_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TABLESPACE_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TEMPFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RMANCONFIGURATION_RECS IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGHISTORY_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_OFFLINERANGE_RECS      IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_ARCHIVEDLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPSET_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPPIECE_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPDFILE_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFILECOPY_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BKDFCORRUPTION_RECS    IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFCOPYCORRUPTION_RECS  IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DELETEDOBJECT_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_PROXY_RECS             IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RESERVED4_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DB2_RECS               IN  BINARY_INTEGER                 
                 ,NUM_INCARNATION_RECS       IN  BINARY_INTEGER                 
                 ,NUM_FLASHBACK_RECS         IN  BINARY_INTEGER                 
                 ,NUM_RAINFO_RECS            IN  BINARY_INTEGER                 
                 ,NUM_INSTRSVT_RECS          IN  BINARY_INTEGER                 
                 ,NUM_AGEDFILES_RECS         IN  BINARY_INTEGER                 
                 ,NUM_RMANSTATUS_RECS        IN  BINARY_INTEGER                 
                 ,NUM_THREADINST_RECS        IN  BINARY_INTEGER                 
                 ,NUM_MTR_RECS               IN  BINARY_INTEGER                 
                 ,NUM_DFH_RECS               IN  BINARY_INTEGER)                
    RETURN BINARY_INTEGER IS                                                    
    BEGIN                                                                       
      RETURN CFILECALCSIZELIST(NUM_CKPTPROG_RECS                                
                               ,NUM_THREAD_RECS                                 
                               ,NUM_LOGFILE_RECS                                
                               ,NUM_DATAFILE_RECS                               
                               ,NUM_FILENAME_RECS                               
                               ,NUM_TABLESPACE_RECS                             
                               ,NUM_TEMPFILE_RECS                               
                               ,NUM_RMANCONFIGURATION_RECS                      
                               ,NUM_LOGHISTORY_RECS                             
                               ,NUM_OFFLINERANGE_RECS                           
                               ,NUM_ARCHIVEDLOG_RECS                            
                               ,NUM_BACKUPSET_RECS                              
                               ,NUM_BACKUPPIECE_RECS                            
                               ,NUM_BACKEDUPDFILE_RECS                          
                               ,NUM_BACKEDUPLOG_RECS                            
                               ,NUM_DFILECOPY_RECS                              
                               ,NUM_BKDFCORRUPTION_RECS                         
                               ,NUM_DFCOPYCORRUPTION_RECS                       
                               ,NUM_DELETEDOBJECT_RECS                          
                               ,NUM_PROXY_RECS                                  
                               ,NUM_RESERVED4_RECS                              
                               ,NUM_DB2_RECS                                    
                               ,NUM_INCARNATION_RECS                            
                               ,NUM_FLASHBACK_RECS                              
                               ,NUM_RAINFO_RECS                                 
                               ,NUM_INSTRSVT_RECS                               
                               ,NUM_AGEDFILES_RECS                              
                               ,NUM_RMANSTATUS_RECS                             
                               ,NUM_THREADINST_RECS                             
                               ,0                                               
                               ,0                                               
                               ,0                                               
                               ,0                                               
                               ,0);                                             
    END;                                                                        
                                                                                
  FUNCTION CFILECALCSIZELIST(                                                   
                  NUM_CKPTPROG_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_THREAD_RECS            IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGFILE_RECS           IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DATAFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_FILENAME_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TABLESPACE_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TEMPFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RMANCONFIGURATION_RECS IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGHISTORY_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_OFFLINERANGE_RECS      IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_ARCHIVEDLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPSET_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPPIECE_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPDFILE_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFILECOPY_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BKDFCORRUPTION_RECS    IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFCOPYCORRUPTION_RECS  IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DELETEDOBJECT_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_PROXY_RECS             IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RESERVED4_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DB2_RECS               IN  BINARY_INTEGER                 
                 ,NUM_INCARNATION_RECS       IN  BINARY_INTEGER                 
                 ,NUM_FLASHBACK_RECS         IN  BINARY_INTEGER                 
                 ,NUM_RAINFO_RECS            IN  BINARY_INTEGER                 
                 ,NUM_INSTRSVT_RECS          IN  BINARY_INTEGER                 
                 ,NUM_AGEDFILES_RECS         IN  BINARY_INTEGER                 
                 ,NUM_RMANSTATUS_RECS        IN  BINARY_INTEGER                 
                 ,NUM_THREADINST_RECS        IN  BINARY_INTEGER                 
                 ,NUM_MTR_RECS               IN  BINARY_INTEGER                 
                 ,NUM_DFH_RECS               IN  BINARY_INTEGER                 
                 ,NUM_SDM_RECS               IN  BINARY_INTEGER                 
                 ,NUM_GRP_RECS               IN  BINARY_INTEGER                 
                 ,NUM_RP_RECS                IN  BINARY_INTEGER)                
    RETURN BINARY_INTEGER IS                                                    
    BEGIN                                                                       
        RETURN CFILECALCSIZELIST(NUM_CKPTPROG_RECS                              
                                ,NUM_THREAD_RECS                                
                                ,NUM_LOGFILE_RECS                               
                                ,NUM_DATAFILE_RECS                              
                                ,NUM_FILENAME_RECS                              
                                ,NUM_TABLESPACE_RECS                            
                                ,NUM_TEMPFILE_RECS                              
                                ,NUM_RMANCONFIGURATION_RECS                     
                                ,NUM_LOGHISTORY_RECS                            
                                ,NUM_OFFLINERANGE_RECS                          
                                ,NUM_ARCHIVEDLOG_RECS                           
                                ,NUM_BACKUPSET_RECS                             
                                ,NUM_BACKUPPIECE_RECS                           
                                ,NUM_BACKEDUPDFILE_RECS                         
                                ,NUM_BACKEDUPLOG_RECS                           
                                ,NUM_DFILECOPY_RECS                             
                                ,NUM_BKDFCORRUPTION_RECS                        
                                ,NUM_DFCOPYCORRUPTION_RECS                      
                                ,NUM_DELETEDOBJECT_RECS                         
                                ,NUM_PROXY_RECS                                 
                                ,NUM_RESERVED4_RECS                             
                                ,NUM_DB2_RECS                                   
                                ,NUM_INCARNATION_RECS                           
                                ,NUM_FLASHBACK_RECS                             
                                ,NUM_RAINFO_RECS                                
                                ,NUM_INSTRSVT_RECS                              
                                ,NUM_AGEDFILES_RECS                             
                                ,NUM_RMANSTATUS_RECS                            
                                ,NUM_THREADINST_RECS                            
                                ,NUM_MTR_RECS                                   
                                ,NUM_DFH_RECS                                   
                                ,NUM_SDM_RECS                                   
                                ,NUM_GRP_RECS                                   
                                ,NUM_RP_RECS                                    
                                ,0                                              
                                ,0                                              
                                ,0);                                            
     END;                                                                       
                                                                                
  FUNCTION CFILECALCSIZELIST(                                                   
                  NUM_CKPTPROG_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_THREAD_RECS            IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGFILE_RECS           IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DATAFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_FILENAME_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TABLESPACE_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_TEMPFILE_RECS          IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RMANCONFIGURATION_RECS IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_LOGHISTORY_RECS        IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_OFFLINERANGE_RECS      IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_ARCHIVEDLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPSET_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKUPPIECE_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPDFILE_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BACKEDUPLOG_RECS       IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFILECOPY_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_BKDFCORRUPTION_RECS    IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DFCOPYCORRUPTION_RECS  IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DELETEDOBJECT_RECS     IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_PROXY_RECS             IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_RESERVED4_RECS         IN  BINARY_INTEGER  DEFAULT 0      
                 ,NUM_DB2_RECS               IN  BINARY_INTEGER                 
                 ,NUM_INCARNATION_RECS       IN  BINARY_INTEGER                 
                 ,NUM_FLASHBACK_RECS         IN  BINARY_INTEGER                 
                 ,NUM_RAINFO_RECS            IN  BINARY_INTEGER                 
                 ,NUM_INSTRSVT_RECS          IN  BINARY_INTEGER                 
                 ,NUM_AGEDFILES_RECS         IN  BINARY_INTEGER                 
                 ,NUM_RMANSTATUS_RECS        IN  BINARY_INTEGER                 
                 ,NUM_THREADINST_RECS        IN  BINARY_INTEGER                 
                 ,NUM_MTR_RECS               IN  BINARY_INTEGER                 
                 ,NUM_DFH_RECS               IN  BINARY_INTEGER                 
                 ,NUM_SDM_RECS               IN  BINARY_INTEGER                 
                 ,NUM_GRP_RECS               IN  BINARY_INTEGER                 
                 ,NUM_RP_RECS                IN  BINARY_INTEGER                 
                 ,NUM_BCR_RECS               IN  BINARY_INTEGER                 
                 ,NUM_ACM_RECS               IN  BINARY_INTEGER                 
                 ,NUM_RLR_RECS               IN  BINARY_INTEGER)                
                                                                                
    RETURN BINARY_INTEGER IS                                                    
        RETURNVALUE  BINARY_INTEGER;                                            
    BEGIN                                                                       
        ICDSTART(49);                                                           
        RETURNVALUE := KRBICSL(NUM_CKPTPROG_RECS                                
                               ,NUM_THREAD_RECS                                 
                               ,NUM_LOGFILE_RECS                                
                               ,NUM_DATAFILE_RECS                               
                               ,NUM_FILENAME_RECS                               
                               ,NUM_TABLESPACE_RECS                             
                               ,NUM_TEMPFILE_RECS                               
                               ,NUM_RMANCONFIGURATION_RECS                      
                               ,NUM_LOGHISTORY_RECS                             
                               ,NUM_OFFLINERANGE_RECS                           
                               ,NUM_ARCHIVEDLOG_RECS                            
                               ,NUM_BACKUPSET_RECS                              
                               ,NUM_BACKUPPIECE_RECS                            
                               ,NUM_BACKEDUPDFILE_RECS                          
                               ,NUM_BACKEDUPLOG_RECS                            
                               ,NUM_DFILECOPY_RECS                              
                               ,NUM_BKDFCORRUPTION_RECS                         
                               ,NUM_DFCOPYCORRUPTION_RECS                       
                               ,NUM_DELETEDOBJECT_RECS                          
                               ,NUM_PROXY_RECS                                  
                               ,NUM_RESERVED4_RECS                              
                               ,NUM_DB2_RECS                                    
                               ,NUM_INCARNATION_RECS                            
                               ,NUM_FLASHBACK_RECS                              
                               ,NUM_RAINFO_RECS                                 
                               ,NUM_INSTRSVT_RECS                               
                               ,NUM_AGEDFILES_RECS                              
                               ,NUM_RMANSTATUS_RECS                             
                               ,NUM_THREADINST_RECS                             
                               ,NUM_MTR_RECS                                    
                               ,NUM_DFH_RECS                                    
                               ,NUM_SDM_RECS                                    
                               ,NUM_GRP_RECS                                    
                               ,NUM_RP_RECS                                     
                               ,NUM_BCR_RECS                                    
                               ,NUM_ACM_RECS                                    
                               ,NUM_RLR_RECS);                                  
        ICDFINISH;                                                              
        RETURN RETURNVALUE;                                                     
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  FUNCTION CFILECALCSIZEARRAY( NUM_RECS  IN  NRECS_ARRAY )                      
    RETURN BINARY_INTEGER IS                                                    
        RETURNVALUE  BINARY_INTEGER;                                            
    BEGIN                                                                       
        ICDSTART(50);                                                           
        RETURNVALUE := KRBICSL( NUM_RECS( 1)                                    
                               ,NUM_RECS( 2)                                    
                               ,NUM_RECS( 3)                                    
                               ,NUM_RECS( 4)                                    
                               ,NUM_RECS( 5)                                    
                               ,NUM_RECS( 6)                                    
                               ,NUM_RECS( 7)                                    
                               ,NUM_RECS( 8)                                    
                               ,NUM_RECS( 9)                                    
                               ,NUM_RECS(10)                                    
                               ,NUM_RECS(11)                                    
                               ,NUM_RECS(12)                                    
                               ,NUM_RECS(13)                                    
                               ,NUM_RECS(14)                                    
                               ,NUM_RECS(15)                                    
                               ,NUM_RECS(16)                                    
                               ,NUM_RECS(17)                                    
                               ,NUM_RECS(18)                                    
                               ,NUM_RECS(19)                                    
                               ,NUM_RECS(20)                                    
                               ,NUM_RECS(21)                                    
                               ,NUM_RECS(22)                                    
                               ,NUM_RECS(23)                                    
                               ,NUM_RECS(24)                                    
                               ,NUM_RECS(25)                                    
                               ,NUM_RECS(26)                                    
                               ,NUM_RECS(27)                                    
                               ,NUM_RECS(28)                                    
                               ,NUM_RECS(29)                                    
                               ,NUM_RECS(30)                                    
                               ,NUM_RECS(31)                                    
                               ,NUM_RECS(32)                                    
                               ,NUM_RECS(33)                                    
                               ,NUM_RECS(34)                                    
                               ,NUM_RECS(35)                                    
                               ,NUM_RECS(36)                                    
                               ,NUM_RECS(37));                                  
        ICDFINISH;                                                              
        RETURN RETURNVALUE;                                                     
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
   END;                                                                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDF( FNAME  IN  VARCHAR2 );                                      
  PRAGMA INTERFACE (C, KRBIDF);                                                 
                                                                                
                                                                                
  PROCEDURE DELETEFILE( FNAME  IN  VARCHAR2 ) IS                                
        INPUT_FNAME  VARCHAR2(513) NOT NULL := ' ';                             
    BEGIN                                                                       
        ICDSTART(51, CHKEVENTS=>TRUE);                                          
        INPUT_FNAME := FNAME;                                                   
        KRBIDF(INPUT_FNAME);                                                    
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICBS( OP                 IN  VARCHAR2                            
                    ,RECID              IN  NUMBER                              
                    ,STAMP              IN  NUMBER                              
                    ,SET_COUNT          IN  NUMBER                              
                    ,KEEP_OPTIONS       IN  BINARY_INTEGER                      
                    ,KEEP_UNTIL         IN  NUMBER);                            
  PRAGMA INTERFACE (C, KRBICBS);                                                
                                                                                
  PROCEDURE CHANGEBACKUPSET( RECID             IN  NUMBER                       
                            ,STAMP             IN  NUMBER                       
                            ,SET_COUNT         IN  NUMBER                       
                            ,KEEP_OPTIONS      IN  BINARY_INTEGER               
                            ,KEEP_UNTIL        IN  NUMBER ) IS                  
    BEGIN                                                                       
        ICDSTART(52, CHKEVENTS=>TRUE);                                          
        KRBICBS('K', RECID, STAMP, SET_COUNT, KEEP_OPTIONS, KEEP_UNTIL);        
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDBP( OP         IN  VARCHAR2                                    
                    ,RECID      IN  NUMBER                                      
                    ,STAMP      IN  NUMBER                                      
                    ,HANDLE     IN  VARCHAR2                                    
                    ,SET_STAMP  IN  NUMBER                                      
                    ,SET_COUNT  IN  NUMBER                                      
                    ,PIECENO    IN  BINARY_INTEGER                              
                    ,PARAMS     IN  VARCHAR2 DEFAULT NULL                       
                    ,FORCE      IN  BINARY_INTEGER                              
                    ,HDL_ISDISK IN  BINARY_INTEGER                              
                    ,MEDIA      OUT VARCHAR2);                                  
  PRAGMA INTERFACE (C, KRBIDBP);                                                
                                                                                
  PROCEDURE DELETEBACKUPPIECE( RECID      IN  NUMBER                            
                              ,STAMP      IN  NUMBER                            
                              ,HANDLE     IN  VARCHAR2                          
                              ,SET_STAMP  IN  NUMBER                            
                              ,SET_COUNT  IN  NUMBER                            
                              ,PIECENO    IN  BINARY_INTEGER                    
                              ,PARAMS     IN  VARCHAR2 DEFAULT NULL ) IS        
    BEGIN                                                                       
        CHANGEBACKUPPIECE(RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT, PIECENO,  
                'D', PARAMS, 0);                                                
    END;                                                                        
                                                                                
  PROCEDURE DELETEBACKUPPIECE( RECID      IN  NUMBER                            
                              ,STAMP      IN  NUMBER                            
                              ,HANDLE     IN  VARCHAR2                          
                              ,SET_STAMP  IN  NUMBER                            
                              ,SET_COUNT  IN  NUMBER                            
                              ,PIECENO    IN  BINARY_INTEGER                    
                              ,PARAMS     IN  VARCHAR2 DEFAULT NULL             
                              ,FORCE      IN  BINARY_INTEGER) IS                
    BEGIN                                                                       
        CHANGEBACKUPPIECE(RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT, PIECENO,  
                'D', PARAMS, FORCE);                                            
    END;                                                                        
                                                                                
  PROCEDURE CHANGEBACKUPPIECE( RECID      IN  NUMBER,                           
                               STAMP      IN  NUMBER,                           
                               HANDLE     IN  VARCHAR2,                         
                               SET_STAMP  IN  NUMBER,                           
                               SET_COUNT  IN  NUMBER,                           
                               PIECENO    IN  BINARY_INTEGER,                   
                               STATUS     IN  VARCHAR2,                         
                               PARAMS     IN  VARCHAR2 DEFAULT NULL ) IS        
    BEGIN                                                                       
        CHANGEBACKUPPIECE(RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT, PIECENO,  
                          STATUS, PARAMS, 0);                                   
    END;                                                                        
                                                                                
  PROCEDURE CHANGEBACKUPPIECE( RECID      IN  NUMBER,                           
                               STAMP      IN  NUMBER,                           
                               HANDLE     IN  VARCHAR2,                         
                               SET_STAMP  IN  NUMBER,                           
                               SET_COUNT  IN  NUMBER,                           
                               PIECENO    IN  BINARY_INTEGER,                   
                               STATUS     IN  VARCHAR2,                         
                               PARAMS     IN  VARCHAR2 DEFAULT NULL,            
                               FORCE      IN  BINARY_INTEGER) IS                
        INPUT_RECID      NUMBER          NOT NULL := 0;                         
        INPUT_STAMP      NUMBER          NOT NULL := 0;                         
        INPUT_HANDLE     VARCHAR2(513)   NOT NULL := ' ';                       
        INPUT_SET_STAMP  NUMBER          NOT NULL := 0;                         
        INPUT_SET_COUNT  NUMBER          NOT NULL := 0;                         
        INPUT_STATUS     VARCHAR2(1)     NOT NULL := ' ';                       
        INPUT_PIECENO    BINARY_INTEGER  NOT NULL := 0;                         
        INPUT_FORCE      BINARY_INTEGER  NOT NULL := 0;                         
        MEDIA            VARCHAR2(128)   := ' ';                                
    BEGIN                                                                       
        ICDSTART(53, CHKEVENTS=>TRUE);                                          
                                                                                
        INPUT_RECID     := RECID;                                               
        INPUT_STAMP     := STAMP;                                               
        INPUT_HANDLE    := HANDLE;                                              
        INPUT_SET_STAMP := SET_STAMP;                                           
        INPUT_SET_COUNT := SET_COUNT;                                           
        INPUT_STATUS    := STATUS;                                              
        INPUT_PIECENO   := PIECENO;                                             
        INPUT_FORCE     := FORCE;                                               
                                                                                
                                                                                
                                                                                
        IF HANDLE IS NULL THEN                                                  
           KRBIRERR(19864, 'Handle is NULL');                                   
        END IF;                                                                 
        KRBIDBP(STATUS, RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT, PIECENO,    
                PARAMS, FORCE, 0, MEDIA);                                       
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDDF( OP                 IN     VARCHAR2                         
                    ,RECID              IN     NUMBER                           
                    ,STAMP              IN     NUMBER                           
                    ,FNAME              IN     VARCHAR2                         
                    ,DFNUMBER           IN     BINARY_INTEGER                   
                    ,RESETLOGS_CHANGE   IN     NUMBER                           
                    ,CREATION_CHANGE    IN     NUMBER                           
                    ,CHECKPOINT_CHANGE  IN OUT NUMBER                           
                    ,CHECKPOINT_TIME    IN OUT BINARY_INTEGER                   
                    ,BLKSIZE            IN     NUMBER                           
                    ,KEEP_OPTIONS       IN     BINARY_INTEGER                   
                    ,KEEP_UNTIL         IN     NUMBER                           
                    ,SIGNAL             IN     BINARY_INTEGER                   
                    ,FORCE              IN     BINARY_INTEGER);                 
  PRAGMA INTERFACE (C, KRBIDDF);                                                
                                                                                
  PROCEDURE CHANGEDATAFILECOPY( RECID              IN  NUMBER                   
                               ,STAMP              IN  NUMBER                   
                               ,FNAME              IN  VARCHAR2                 
                               ,DFNUMBER           IN  BINARY_INTEGER           
                               ,RESETLOGS_CHANGE   IN  NUMBER                   
                               ,CREATION_CHANGE    IN  NUMBER                   
                               ,CHECKPOINT_CHANGE  IN  NUMBER                   
                               ,BLKSIZE            IN  NUMBER                   
                               ,NEW_STATUS         IN  VARCHAR2) IS             
  BEGIN                                                                         
      CHANGEDATAFILECOPY(NEW_STATUS, RECID, STAMP, FNAME, DFNUMBER,             
                         RESETLOGS_CHANGE, CREATION_CHANGE,                     
                         CHECKPOINT_CHANGE, BLKSIZE, 0, 0);                     
  END;                                                                          
                                                                                
  PROCEDURE CHANGEDATAFILECOPY( RECID              IN  NUMBER                   
                               ,STAMP              IN  NUMBER                   
                               ,FNAME              IN  VARCHAR2                 
                               ,DFNUMBER           IN  BINARY_INTEGER           
                               ,RESETLOGS_CHANGE   IN  NUMBER                   
                               ,CREATION_CHANGE    IN  NUMBER                   
                               ,CHECKPOINT_CHANGE  IN  NUMBER                   
                               ,BLKSIZE            IN  NUMBER                   
                               ,NEW_STATUS         IN  VARCHAR2                 
                               ,KEEP_OPTIONS       IN  BINARY_INTEGER           
                               ,KEEP_UNTIL         IN  NUMBER) IS               
  BEGIN                                                                         
      CHANGEDATAFILECOPY(RECID, STAMP, FNAME, DFNUMBER,                         
                         RESETLOGS_CHANGE, CREATION_CHANGE,                     
                         CHECKPOINT_CHANGE, BLKSIZE, NEW_STATUS, KEEP_OPTIONS,  
                         KEEP_UNTIL, 0);                                        
  END;                                                                          
                                                                                
  PROCEDURE CHANGEDATAFILECOPY( RECID              IN  NUMBER                   
                               ,STAMP              IN  NUMBER                   
                               ,FNAME              IN  VARCHAR2                 
                               ,DFNUMBER           IN  BINARY_INTEGER           
                               ,RESETLOGS_CHANGE   IN  NUMBER                   
                               ,CREATION_CHANGE    IN  NUMBER                   
                               ,CHECKPOINT_CHANGE  IN  NUMBER                   
                               ,BLKSIZE            IN  NUMBER                   
                               ,NEW_STATUS         IN  VARCHAR2                 
                               ,KEEP_OPTIONS       IN  BINARY_INTEGER           
                               ,KEEP_UNTIL         IN  NUMBER                   
                               ,FORCE              IN  BINARY_INTEGER) IS       
                                                                                
        INPUT_RECID              NUMBER          NOT NULL := 0;                 
        INPUT_STAMP              NUMBER          NOT NULL := 0;                 
        INPUT_FNAME              VARCHAR2(513)   NOT NULL := ' ';               
        INPUT_DFNUMBER           BINARY_INTEGER  NOT NULL := 0;                 
        INPUT_RESETLOGS_CHANGE   NUMBER          NOT NULL := 0;                 
        INPUT_CREATION_CHANGE    NUMBER          NOT NULL := 0;                 
        INPUT_CHECKPOINT_CHANGE  NUMBER          NOT NULL := 0;                 
        INPUT_CHECKPOINT_TIME    BINARY_INTEGER  NOT NULL := 0;                 
        INPUT_BLKSIZE            NUMBER          NOT NULL := 0;                 
        INPUT_STATUS             VARCHAR2(1)     NOT NULL := NEW_STATUS;        
        INPUT_KEEP_OPTIONS       BINARY_INTEGER  NOT NULL := KEEP_OPTIONS;      
        INPUT_KEEP_UNTIL         NUMBER          NOT NULL := KEEP_UNTIL;        
        INPUT_FORCE              BINARY_INTEGER  NOT NULL := FORCE;             
                                                                                
    BEGIN                                                                       
        ICDSTART(54, CHKEVENTS=>TRUE);                                          
                                                                                
        INPUT_RECID := RECID;                                                   
        INPUT_STAMP := STAMP;                                                   
        INPUT_FNAME := FNAME;                                                   
        INPUT_DFNUMBER := DFNUMBER;                                             
        INPUT_RESETLOGS_CHANGE := RESETLOGS_CHANGE;                             
        INPUT_CREATION_CHANGE := CREATION_CHANGE;                               
        INPUT_CHECKPOINT_CHANGE := CHECKPOINT_CHANGE;                           
        INPUT_BLKSIZE := BLKSIZE;                                               
        KRBIDDF(NEW_STATUS, RECID, STAMP, FNAME, DFNUMBER, RESETLOGS_CHANGE,    
                CREATION_CHANGE, INPUT_CHECKPOINT_CHANGE,                       
                INPUT_CHECKPOINT_TIME, BLKSIZE,                                 
                KEEP_OPTIONS, KEEP_UNTIL, 0, FORCE);                            
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE DELETEDATAFILECOPY( RECID              IN  NUMBER                   
                               ,STAMP              IN  NUMBER                   
                               ,FNAME              IN  VARCHAR2                 
                               ,DFNUMBER           IN  BINARY_INTEGER           
                               ,RESETLOGS_CHANGE   IN  NUMBER                   
                               ,CREATION_CHANGE    IN  NUMBER                   
                               ,CHECKPOINT_CHANGE  IN  NUMBER                   
                               ,BLKSIZE            IN  NUMBER                   
                               ,NO_DELETE          IN  BINARY_INTEGER ) IS      
  BEGIN                                                                         
     DELETEDATAFILECOPY(RECID, STAMP, FNAME, DFNUMBER, RESETLOGS_CHANGE,        
                        CREATION_CHANGE, CHECKPOINT_CHANGE, BLKSIZE,            
                        NO_DELETE, 0);                                          
  END;                                                                          
                                                                                
  PROCEDURE DELETEDATAFILECOPY( RECID              IN  NUMBER                   
                               ,STAMP              IN  NUMBER                   
                               ,FNAME              IN  VARCHAR2                 
                               ,DFNUMBER           IN  BINARY_INTEGER           
                               ,RESETLOGS_CHANGE   IN  NUMBER                   
                               ,CREATION_CHANGE    IN  NUMBER                   
                               ,CHECKPOINT_CHANGE  IN  NUMBER                   
                               ,BLKSIZE            IN  NUMBER                   
                               ,NO_DELETE          IN  BINARY_INTEGER           
                               ,FORCE              IN  BINARY_INTEGER ) IS      
                                                                                
        INPUT_NO_DELETE          BINARY_INTEGER  NOT NULL := 0;                 
        OP                       VARCHAR2(1);                                   
        INTERNAL_ERROR           EXCEPTION;                                     
        PRAGMA EXCEPTION_INIT(INTERNAL_ERROR, -600);                            
    BEGIN                                                                       
                                                                                
        INPUT_NO_DELETE := NO_DELETE;                                           
        IF NO_DELETE = 0 THEN                                                   
           OP := 'D';                                                           
        ELSIF NO_DELETE = 1 THEN                                                
           OP := 'R';                                                           
        ELSIF NO_DELETE = 2 THEN                                                
           OP := 'V';                                                           
        ELSE                                                                    
           KRBIRERR(19864, 'Invalid no_delete value: '||TO_CHAR(NO_DELETE));    
        END IF;                                                                 
        CHANGEDATAFILECOPY(RECID, STAMP, FNAME, DFNUMBER, RESETLOGS_CHANGE,     
                           CREATION_CHANGE, CHECKPOINT_CHANGE, BLKSIZE, OP,     
                           0, 0, FORCE);                                        
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDRL( OP                IN  VARCHAR2                             
                    ,RECID             IN  NUMBER                               
                    ,STAMP             IN  NUMBER                               
                    ,FNAME             IN  VARCHAR2                             
                    ,THREAD            IN  NUMBER                               
                    ,SEQUENCE          IN  NUMBER                               
                    ,RESETLOGS_CHANGE  IN  NUMBER                               
                    ,FIRST_CHANGE      IN  NUMBER                               
                    ,BLKSIZE           IN  NUMBER                               
                    ,SIGNAL            IN  BINARY_INTEGER                       
                    ,FORCE             IN  BINARY_INTEGER                       
                    ,TERMINAL          IN  BINARY_INTEGER                       
                    ,FOREIGNAL         IN  BINARY_INTEGER);                     
  PRAGMA INTERFACE (C, KRBIDRL);                                                
                                                                                
  PROCEDURE CHANGEARCHIVEDLOG(RECID             IN  NUMBER                      
                             ,STAMP             IN  NUMBER                      
                             ,FNAME             IN  VARCHAR2                    
                             ,THREAD            IN  NUMBER                      
                             ,SEQUENCE          IN  NUMBER                      
                             ,RESETLOGS_CHANGE  IN  NUMBER                      
                             ,FIRST_CHANGE      IN  NUMBER                      
                             ,BLKSIZE           IN  NUMBER                      
                             ,NEW_STATUS        IN  VARCHAR2 ) IS               
  BEGIN                                                                         
     CHANGEARCHIVEDLOG(RECID, STAMP, FNAME, THREAD, SEQUENCE,                   
                       RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE, NEW_STATUS,     
                       0);                                                      
  END;                                                                          
                                                                                
  PROCEDURE CHANGEARCHIVEDLOG(RECID             IN  NUMBER                      
                             ,STAMP             IN  NUMBER                      
                             ,FNAME             IN  VARCHAR2                    
                             ,THREAD            IN  NUMBER                      
                             ,SEQUENCE          IN  NUMBER                      
                             ,RESETLOGS_CHANGE  IN  NUMBER                      
                             ,FIRST_CHANGE      IN  NUMBER                      
                             ,BLKSIZE           IN  NUMBER                      
                             ,NEW_STATUS        IN  VARCHAR2                    
                             ,FORCE             IN  BINARY_INTEGER ) IS         
  BEGIN                                                                         
     CHANGEARCHIVEDLOG(RECID, STAMP, FNAME, THREAD, SEQUENCE,                   
                       RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE, NEW_STATUS,     
                       FORCE, 0);                                               
  END;                                                                          
                                                                                
  PROCEDURE CHANGEARCHIVEDLOG(RECID             IN  NUMBER                      
                             ,STAMP             IN  NUMBER                      
                             ,FNAME             IN  VARCHAR2                    
                             ,THREAD            IN  NUMBER                      
                             ,SEQUENCE          IN  NUMBER                      
                             ,RESETLOGS_CHANGE  IN  NUMBER                      
                             ,FIRST_CHANGE      IN  NUMBER                      
                             ,BLKSIZE           IN  NUMBER                      
                             ,NEW_STATUS        IN  VARCHAR2                    
                             ,FORCE             IN  BINARY_INTEGER              
                             ,FOREIGNAL         IN  BINARY_INTEGER ) IS         
        INPUT_RECID             NUMBER          NOT NULL := 0;                  
        INPUT_STAMP             NUMBER          NOT NULL := 0;                  
        INPUT_FNAME             VARCHAR2(513)   NOT NULL := ' ';                
        INPUT_THREAD            NUMBER          NOT NULL := 0;                  
        INPUT_SEQUENCE          NUMBER          NOT NULL := 0;                  
        INPUT_RESETLOGS_CHANGE  NUMBER          NOT NULL := 0;                  
        INPUT_FIRST_CHANGE      NUMBER          NOT NULL := 0;                  
        INPUT_BLKSIZE           NUMBER          NOT NULL := 0;                  
        INPUT_FORCE             BINARY_INTEGER  NOT NULL := 0;                  
        INPUT_FOREIGNAL         BINARY_INTEGER  NOT NULL := 0;                  
    BEGIN                                                                       
        ICDSTART(55);                                                           
                                                                                
        INPUT_RECID := RECID;                                                   
        INPUT_STAMP := STAMP;                                                   
        INPUT_FNAME := FNAME;                                                   
        INPUT_THREAD := THREAD;                                                 
        INPUT_SEQUENCE := SEQUENCE;                                             
        INPUT_RESETLOGS_CHANGE := RESETLOGS_CHANGE;                             
        INPUT_FIRST_CHANGE := FIRST_CHANGE;                                     
        INPUT_BLKSIZE := BLKSIZE;                                               
        INPUT_FORCE := FORCE;                                                   
        INPUT_FOREIGNAL := FOREIGNAL;                                           
                                                                                
        IF NEW_STATUS IS NULL THEN                                              
           KRBIRERR(19864, 'Missing archivelog operation');                     
        END IF;                                                                 
        KRBIDRL(NEW_STATUS, RECID, STAMP, FNAME, THREAD, SEQUENCE,              
                RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE, 0, FORCE, 0,           
                FOREIGNAL);                                                     
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE DELETEARCHIVEDLOG(RECID             IN  NUMBER                      
                             ,STAMP             IN  NUMBER                      
                             ,FNAME             IN  VARCHAR2                    
                             ,THREAD            IN  NUMBER                      
                             ,SEQUENCE          IN  NUMBER                      
                             ,RESETLOGS_CHANGE  IN  NUMBER                      
                             ,FIRST_CHANGE      IN  NUMBER                      
                             ,BLKSIZE           IN  NUMBER ) IS                 
    BEGIN                                                                       
        CHANGEARCHIVEDLOG(RECID, STAMP, FNAME, THREAD, SEQUENCE,                
                          RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE, 'D');        
    END;                                                                        
                                                                                
  PROCEDURE DELETEARCHIVEDLOG(RECID             IN  NUMBER                      
                             ,STAMP             IN  NUMBER                      
                             ,FNAME             IN  VARCHAR2                    
                             ,THREAD            IN  NUMBER                      
                             ,SEQUENCE          IN  NUMBER                      
                             ,RESETLOGS_CHANGE  IN  NUMBER                      
                             ,FIRST_CHANGE      IN  NUMBER                      
                             ,BLKSIZE           IN  NUMBER                      
                             ,FORCE             IN  BINARY_INTEGER ) IS         
    BEGIN                                                                       
        CHANGEARCHIVEDLOG(RECID, STAMP, FNAME, THREAD, SEQUENCE,                
                          RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE, 'D', FORCE); 
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE DELETED_GETDBINFO IS                                                
    BEGIN                                                                       
        NULL;                                                                   
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIGFNO( NAME            IN   VARCHAR2                             
                    ,DFNUMBER         OUT  BINARY_INTEGER                       
                    ,CREATION_CHANGE  OUT  NUMBER );                            
  PRAGMA INTERFACE (C, KRBIGFNO);                                               
                                                                                
                                                                                
  PROCEDURE GETFNO( NAME             IN   VARCHAR2                              
                   ,DFNUMBER         OUT  BINARY_INTEGER                        
                   ,CREATION_CHANGE  OUT  NUMBER ) IS                           
        INPUT_NAME  VARCHAR2(513) NOT NULL := ' ';                              
    BEGIN                                                                       
        ICDSTART(56);                                                           
        INPUT_NAME := NAME;                                                     
        KRBIGFNO(INPUT_NAME, DFNUMBER, CREATION_CHANGE);                        
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  FUNCTION KRBIUFR(DFNUMBER     IN BINARY_INTEGER,                              
                   MAX_CORRUPT  IN BINARY_INTEGER  DEFAULT 0,                   
                   UPDATE_FUZZINESS IN BOOLEAN DEFAULT TRUE,                    
                   CHECK_LOGICAL IN BOOLEAN) RETURN NUMBER;                     
  PRAGMA INTERFACE (C, KRBIUFR);                                                
                                                                                
  FUNCTION SCANDATAFILE(DFNUMBER    IN BINARY_INTEGER,                          
                        MAX_CORRUPT IN BINARY_INTEGER DEFAULT 0,                
                        UPDATE_FUZZINESS IN BOOLEAN DEFAULT TRUE)               
           RETURN NUMBER                                                        
    IS                                                                          
    BEGIN                                                                       
        RETURN SCANDATAFILE(DFNUMBER, MAX_CORRUPT, UPDATE_FUZZINESS, FALSE);    
    END;                                                                        
                                                                                
  FUNCTION SCANDATAFILE(DFNUMBER    IN BINARY_INTEGER,                          
                        MAX_CORRUPT IN BINARY_INTEGER DEFAULT 0,                
                        UPDATE_FUZZINESS IN BOOLEAN DEFAULT TRUE,               
                        CHECK_LOGICAL IN BOOLEAN)                               
           RETURN NUMBER                                                        
    IS                                                                          
        INPUT_DFNUMBER  BINARY_INTEGER NOT NULL := 0;                           
        SCN             NUMBER;                                                 
    BEGIN                                                                       
        ICDSTART(57);                                                           
        INPUT_DFNUMBER := DFNUMBER;                                             
        SCN := KRBIUFR(DFNUMBER, MAX_CORRUPT, UPDATE_FUZZINESS, CHECK_LOGICAL); 
        ICDFINISH;                                                              
        RETURN SCN;                                                             
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIUFC(RECID        IN  NUMBER,                                     
                   STAMP        IN  NUMBER,                                     
                   MAX_CORRUPT  IN  BINARY_INTEGER  DEFAULT 0,                  
                   ISBACKUP     IN  BOOLEAN DEFAULT FALSE,                      
                   UPDATE_FUZZINESS IN BOOLEAN DEFAULT TRUE,                    
                   CHECK_LOGICAL IN BOOLEAN) RETURN NUMBER;                     
  PRAGMA INTERFACE (C, KRBIUFC);                                                
                                                                                
                                                                                
  FUNCTION                                                                      
         SCANDATAFILECOPY(RECID  IN NUMBER,                                     
                          STAMP  IN NUMBER,                                     
                          MAX_CORRUPT IN BINARY_INTEGER DEFAULT 0,              
                          ISBACKUP    IN BOOLEAN DEFAULT FALSE,                 
                          UPDATE_FUZZINESS IN BOOLEAN DEFAULT TRUE)             
         RETURN NUMBER                                                          
    IS                                                                          
    BEGIN                                                                       
        RETURN SCANDATAFILECOPY(RECID, STAMP, MAX_CORRUPT, ISBACKUP,            
                                UPDATE_FUZZINESS, FALSE);                       
    END;                                                                        
                                                                                
  FUNCTION                                                                      
         SCANDATAFILECOPY(RECID  IN NUMBER,                                     
                          STAMP  IN NUMBER,                                     
                          MAX_CORRUPT IN BINARY_INTEGER DEFAULT 0,              
                          ISBACKUP    IN BOOLEAN DEFAULT FALSE,                 
                          UPDATE_FUZZINESS IN BOOLEAN DEFAULT TRUE,             
                          CHECK_LOGICAL IN BOOLEAN)                             
         RETURN NUMBER                                                          
    IS                                                                          
        INPUT_RECID NUMBER NOT NULL := 0;                                       
        INPUT_STAMP NUMBER NOT NULL := 0;                                       
        INPUT_ISBACKUP  BOOLEAN  NOT NULL := FALSE;                             
        SCN        NUMBER;                                                      
    BEGIN                                                                       
        ICDSTART(58);                                                           
        INPUT_RECID := RECID;                                                   
        INPUT_STAMP := STAMP;                                                   
        INPUT_ISBACKUP := ISBACKUP;                                             
        SCN := KRBIUFC(RECID, STAMP, MAX_CORRUPT, ISBACKUP, UPDATE_FUZZINESS,   
                       CHECK_LOGICAL);                                          
        ICDFINISH;                                                              
        RETURN SCN;                                                             
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISAL(RECID IN  NUMBER, STAMP IN  NUMBER);                        
  PRAGMA INTERFACE (C, KRBISAL);                                                
                                                                                
  PROCEDURE                                                                     
         SCANARCHIVEDLOG(RECID IN NUMBER, STAMP IN NUMBER)                      
    IS                                                                          
        INPUT_RECID NUMBER NOT NULL := 0;                                       
        INPUT_STAMP NUMBER NOT NULL := 0;                                       
    BEGIN                                                                       
        ICDSTART(59);                                                           
        INPUT_RECID := RECID;                                                   
        INPUT_STAMP := STAMP;                                                   
        KRBISAL(RECID, STAMP);                                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISTC( COPY_RECID  IN  NUMBER                                     
                    ,COPY_STAMP  IN  NUMBER                                     
                    ,CATALOG     IN  BOOLEAN );                                 
  PRAGMA INTERFACE (C, KRBISTC);                                                
                                                                                
  PROCEDURE SWITCHTOCOPY( COPY_RECID  IN  NUMBER                                
                         ,COPY_STAMP  IN  NUMBER ) IS                           
  BEGIN                                                                         
     SWITCHTOCOPY(COPY_RECID, COPY_STAMP, TRUE);                                
  END;                                                                          
                                                                                
  PROCEDURE SWITCHTOCOPY( COPY_RECID  IN  NUMBER                                
                         ,COPY_STAMP  IN  NUMBER                                
                         ,CATALOG     IN  BOOLEAN ) IS                          
        RECID  NUMBER     NOT NULL := 0;                                        
        STAMP  NUMBER     NOT NULL := 0;                                        
    BEGIN                                                                       
        ICDSTART(60);                                                           
        RECID := COPY_RECID;                                                    
        STAMP := COPY_STAMP;                                                    
        KRBISTC(RECID, STAMP, CATALOG);                                         
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  FUNCTION KRBINFN(FNAME IN VARCHAR2) RETURN VARCHAR2;                          
  PRAGMA INTERFACE (C, KRBINFN);                                                
                                                                                
                                                                                
  FUNCTION NORMALIZEFILENAME(FNAME IN VARCHAR2) RETURN VARCHAR2 IS              
        OUTPUT VARCHAR2(512);                                                   
    BEGIN                                                                       
        ICDSTART(61);                                                           
        OUTPUT := KRBINFN(FNAME);                                               
        ICDFINISH;                                                              
        RETURN OUTPUT;                                                          
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIVBP( OP         IN  VARCHAR2                                     
                   ,RECID      IN  NUMBER                                       
                   ,STAMP      IN  NUMBER                                       
                   ,HANDLE     IN  VARCHAR2                                     
                   ,SET_STAMP  IN  NUMBER                                       
                   ,SET_COUNT  IN  NUMBER                                       
                   ,PIECENO    IN  BINARY_INTEGER                               
                   ,PARAMS     IN  VARCHAR2 DEFAULT NULL                        
                   ,FORCE      IN  BINARY_INTEGER                               
                   ,HDL_ISDISK IN  BINARY_INTEGER                               
                   ,MEDIA      OUT VARCHAR2)                                    
                   RETURN BINARY_INTEGER;                                       
  PRAGMA INTERFACE (C, KRBIVBP);                                                
                                                                                
                                                                                
  FUNCTION VALIDATEBACKUPPIECE(RECID      IN  NUMBER                            
                               ,STAMP     IN  NUMBER                            
                               ,HANDLE    IN  VARCHAR2                          
                               ,SET_STAMP IN  NUMBER                            
                               ,SET_COUNT IN  NUMBER                            
                               ,PIECENO   IN  BINARY_INTEGER                    
                               ,PARAMS    IN  VARCHAR2 DEFAULT NULL)            
                               RETURN BINARY_INTEGER IS                         
  BEGIN                                                                         
     RETURN VALIDATEBACKUPPIECE(RECID, STAMP, HANDLE, SET_STAMP,                
                                SET_COUNT, PIECENO, PARAMS, 0);                 
  END;                                                                          
                                                                                
  FUNCTION VALIDATEBACKUPPIECE(RECID       IN  NUMBER                           
                               ,STAMP      IN  NUMBER                           
                               ,HANDLE     IN  VARCHAR2                         
                               ,SET_STAMP  IN  NUMBER                           
                               ,SET_COUNT  IN  NUMBER                           
                               ,PIECENO    IN  BINARY_INTEGER                   
                               ,PARAMS     IN  VARCHAR2 DEFAULT NULL            
                               ,HDL_ISDISK IN  BINARY_INTEGER)                  
                               RETURN BINARY_INTEGER IS                         
        MEDIA  VARCHAR2(128);                                                   
  BEGIN                                                                         
     RETURN VALIDATEBACKUPPIECE(RECID, STAMP, HANDLE, SET_STAMP,                
                                SET_COUNT, PIECENO, PARAMS, HDL_ISDISK, MEDIA); 
  END;                                                                          
                                                                                
  FUNCTION VALIDATEBACKUPPIECE(RECID       IN  NUMBER                           
                               ,STAMP      IN  NUMBER                           
                               ,HANDLE     IN  VARCHAR2                         
                               ,SET_STAMP  IN  NUMBER                           
                               ,SET_COUNT  IN  NUMBER                           
                               ,PIECENO    IN  BINARY_INTEGER                   
                               ,PARAMS     IN  VARCHAR2 DEFAULT NULL            
                               ,HDL_ISDISK IN  BINARY_INTEGER                   
                               ,MEDIA      OUT  VARCHAR2)                       
                               RETURN BINARY_INTEGER IS                         
        OUTPUT BINARY_INTEGER;                                                  
    BEGIN                                                                       
        ICDSTART(62, CHKEVENTS=>TRUE);                                          
        IF HANDLE IS NULL THEN                                                  
           KRBIRERR(19864, 'Handle is NULL');                                   
        END IF;                                                                 
        OUTPUT := KRBIVBP('V', RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT,      
                          PIECENO, PARAMS, 0, HDL_ISDISK, MEDIA);               
        ICDFINISH;                                                              
        RETURN OUTPUT;                                                          
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  FUNCTION CROSSCHECKBACKUPPIECE(RECID      IN  NUMBER                          
                                 ,STAMP     IN  NUMBER                          
                                 ,HANDLE    IN  VARCHAR2                        
                                 ,SET_STAMP IN  NUMBER                          
                                 ,SET_COUNT IN  NUMBER                          
                                 ,PIECENO   IN  BINARY_INTEGER                  
                                 ,PARAMS    IN  VARCHAR2 DEFAULT NULL)          
                                 RETURN BINARY_INTEGER IS                       
        OUTPUT BINARY_INTEGER;                                                  
        MEDIA  VARCHAR2(128);                                                   
    BEGIN                                                                       
        ICDSTART(63);                                                           
        IF HANDLE IS NULL THEN                                                  
           KRBIRERR(19864, 'Handle is NULL');                                   
        END IF;                                                                 
        OUTPUT := KRBIVBP('V', RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT,      
                          PIECENO, PARAMS, 0, 0, MEDIA);                        
        IF BITAND(OUTPUT, VALIDATE_FILE_DIFFERENT) = 0 THEN                     
           KRBIDBP('A', RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT, PIECENO,    
                   PARAMS, 0, 0, MEDIA);                                        
        ELSE                                                                    
           KRBIDBP('X', RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT, PIECENO,    
                   PARAMS, 0, 0, MEDIA);                                        
        END IF;                                                                 
        ICDFINISH;                                                              
        RETURN OUTPUT;                                                          
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIVDC( OP                IN     VARCHAR2                           
                   ,RECID             IN     NUMBER                             
                   ,STAMP             IN     NUMBER                             
                   ,FNAME             IN     VARCHAR2                           
                   ,DFNUMBER          IN     BINARY_INTEGER                     
                   ,RESETLOGS_CHANGE  IN     NUMBER                             
                   ,CREATION_CHANGE   IN     NUMBER                             
                   ,CHECKPOINT_CHANGE IN OUT NUMBER                             
                   ,CHECKPOINT_TIME   IN OUT BINARY_INTEGER                     
                   ,BLKSIZE           IN     NUMBER                             
                   ,KEEP_OPTIONS      IN     BINARY_INTEGER                     
                   ,KEEP_UNTIL        IN     NUMBER                             
                   ,SIGNAL            IN     BINARY_INTEGER                     
                   ,FORCE             IN     BINARY_INTEGER)                    
                   RETURN BINARY_INTEGER;                                       
  PRAGMA INTERFACE (C, KRBIVDC);                                                
                                                                                
                                                                                
  FUNCTION VALIDATEDATAFILECOPY( RECID             IN  NUMBER                   
                                ,STAMP             IN  NUMBER                   
                                ,FNAME             IN  VARCHAR2                 
                                ,DFNUMBER          IN  BINARY_INTEGER           
                                ,RESETLOGS_CHANGE  IN  NUMBER                   
                                ,CREATION_CHANGE   IN  NUMBER                   
                                ,CHECKPOINT_CHANGE IN  NUMBER                   
                                ,BLKSIZE           IN  NUMBER)                  
                                RETURN BINARY_INTEGER IS                        
    BEGIN                                                                       
        RETURN VALIDATEDATAFILECOPY(RECID, STAMP, FNAME, DFNUMBER,              
                                    RESETLOGS_CHANGE, CREATION_CHANGE,          
                                    CHECKPOINT_CHANGE, BLKSIZE, 0);             
    END;                                                                        
                                                                                
  FUNCTION VALIDATEDATAFILECOPY( RECID             IN  NUMBER                   
                                ,STAMP             IN  NUMBER                   
                                ,FNAME             IN  VARCHAR2                 
                                ,DFNUMBER          IN  BINARY_INTEGER           
                                ,RESETLOGS_CHANGE  IN  NUMBER                   
                                ,CREATION_CHANGE   IN  NUMBER                   
                                ,CHECKPOINT_CHANGE IN  NUMBER                   
                                ,BLKSIZE           IN  NUMBER                   
                                ,SIGNAL            IN  BINARY_INTEGER)          
                                RETURN BINARY_INTEGER IS                        
        INPUT_CHECKPOINT_CHANGE  NUMBER NOT NULL := 0;                          
        INPUT_CHECKPOINT_TIME    BINARY_INTEGER  NOT NULL := 0;                 
        OUTPUT                   BINARY_INTEGER;                                
    BEGIN                                                                       
        IF CHECKPOINT_CHANGE IS NOT NULL THEN                                   
           INPUT_CHECKPOINT_CHANGE := CHECKPOINT_CHANGE;                        
        END IF;                                                                 
        OUTPUT := VALIDATEDATAFILECOPY( RECID, STAMP, FNAME, DFNUMBER,          
                                        RESETLOGS_CHANGE, CREATION_CHANGE,      
                                        INPUT_CHECKPOINT_CHANGE,                
                                        INPUT_CHECKPOINT_TIME,                  
                                        BLKSIZE, SIGNAL);                       
        RETURN OUTPUT;                                                          
    END;                                                                        
                                                                                
  FUNCTION VALIDATEDATAFILECOPY( RECID             IN     NUMBER                
                                ,STAMP             IN     NUMBER                
                                ,FNAME             IN     VARCHAR2              
                                ,DFNUMBER          IN     BINARY_INTEGER        
                                ,RESETLOGS_CHANGE  IN     NUMBER                
                                ,CREATION_CHANGE   IN     NUMBER                
                                ,CHECKPOINT_CHANGE IN OUT NUMBER                
                                ,CHECKPOINT_TIME   IN OUT BINARY_INTEGER        
                                ,BLKSIZE           IN     NUMBER                
                                ,SIGNAL            IN     BINARY_INTEGER)       
                                RETURN BINARY_INTEGER IS                        
        OUTPUT BINARY_INTEGER;                                                  
        CKPTIM BINARY_INTEGER;                                                  
        CKPSCN NUMBER;                                                          
        RLGSCN NUMBER;                                                          
    BEGIN                                                                       
        ICDSTART(64);                                                           
        IF CHECKPOINT_TIME IS NULL THEN                                         
          CKPTIM := 0;                                                          
        ELSE                                                                    
          CKPTIM := CHECKPOINT_TIME;                                            
        END IF;                                                                 
        IF CHECKPOINT_CHANGE IS NULL THEN                                       
          CKPSCN := 0;                                                          
        ELSE                                                                    
          CKPSCN := CHECKPOINT_CHANGE;                                          
        END IF;                                                                 
        IF RESETLOGS_CHANGE IS NULL THEN                                        
          RLGSCN := 0;                                                          
        ELSE                                                                    
          RLGSCN := RESETLOGS_CHANGE;                                           
        END IF;                                                                 
                                                                                
        OUTPUT := KRBIVDC('V', RECID, STAMP, FNAME, DFNUMBER, RLGSCN,           
                          CREATION_CHANGE, CKPSCN, CKPTIM,                      
                          BLKSIZE, 0, 0, SIGNAL, 0);                            
                                                                                
        IF CHECKPOINT_TIME IS NOT NULL THEN                                     
           CHECKPOINT_TIME := CKPTIM;                                           
        END IF;                                                                 
        IF CHECKPOINT_CHANGE IS NOT NULL THEN                                   
           CHECKPOINT_CHANGE := CKPSCN;                                         
        END IF;                                                                 
                                                                                
        ICDFINISH;                                                              
        RETURN OUTPUT;                                                          
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIVAL( OP               IN  VARCHAR2                               
                   ,RECID            IN  NUMBER                                 
                   ,STAMP            IN  NUMBER                                 
                   ,FNAME            IN  VARCHAR2                               
                   ,THREAD           IN  NUMBER                                 
                   ,SEQUENCE         IN  NUMBER                                 
                   ,RESETLOGS_CHANGE IN  NUMBER                                 
                   ,FIRST_CHANGE     IN  NUMBER                                 
                   ,BLKSIZE          IN  NUMBER                                 
                   ,SIGNAL           IN  BINARY_INTEGER                         
                   ,FORCE            IN  BINARY_INTEGER                         
                   ,TERMINAL         IN  BINARY_INTEGER                         
                   ,FOREIGNAL        IN  BINARY_INTEGER)                        
                   RETURN BINARY_INTEGER;                                       
  PRAGMA INTERFACE (C, KRBIVAL);                                                
                                                                                
                                                                                
  FUNCTION VALIDATEARCHIVEDLOG( RECID            IN  NUMBER                     
                               ,STAMP            IN  NUMBER                     
                               ,FNAME            IN  VARCHAR2                   
                               ,THREAD           IN  NUMBER                     
                               ,SEQUENCE         IN  NUMBER                     
                               ,RESETLOGS_CHANGE IN  NUMBER                     
                               ,FIRST_CHANGE     IN  NUMBER                     
                               ,BLKSIZE          IN  NUMBER)                    
                               RETURN BINARY_INTEGER IS                         
    BEGIN                                                                       
        RETURN VALIDATEARCHIVEDLOG(RECID, STAMP, FNAME, THREAD, SEQUENCE,       
                               RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE, 0);     
    END;                                                                        
                                                                                
                                                                                
  FUNCTION VALIDATEARCHIVEDLOG( RECID            IN  NUMBER                     
                               ,STAMP            IN  NUMBER                     
                               ,FNAME            IN  VARCHAR2                   
                               ,THREAD           IN  NUMBER                     
                               ,SEQUENCE         IN  NUMBER                     
                               ,RESETLOGS_CHANGE IN  NUMBER                     
                               ,FIRST_CHANGE     IN  NUMBER                     
                               ,BLKSIZE          IN  NUMBER                     
                               ,SIGNAL           IN  BINARY_INTEGER)            
                               RETURN BINARY_INTEGER IS                         
        OUTPUT BINARY_INTEGER;                                                  
    BEGIN                                                                       
        RETURN VALIDATEARCHIVEDLOG(RECID, STAMP, FNAME, THREAD, SEQUENCE,       
                               RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE,         
                               SIGNAL, 0);                                      
    END;                                                                        
                                                                                
  FUNCTION VALIDATEARCHIVEDLOG( RECID            IN  NUMBER                     
                               ,STAMP            IN  NUMBER                     
                               ,FNAME            IN  VARCHAR2                   
                               ,THREAD           IN  NUMBER                     
                               ,SEQUENCE         IN  NUMBER                     
                               ,RESETLOGS_CHANGE IN  NUMBER                     
                               ,FIRST_CHANGE     IN  NUMBER                     
                               ,BLKSIZE          IN  NUMBER                     
                               ,SIGNAL           IN  BINARY_INTEGER             
                               ,TERMINAL         IN  BINARY_INTEGER)            
                               RETURN BINARY_INTEGER IS                         
    BEGIN                                                                       
        RETURN VALIDATEARCHIVEDLOG(RECID, STAMP, FNAME, THREAD, SEQUENCE,       
                               RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE,         
                               SIGNAL, TERMINAL, 0);                            
    END;                                                                        
                                                                                
  FUNCTION VALIDATEARCHIVEDLOG( RECID            IN  NUMBER                     
                               ,STAMP            IN  NUMBER                     
                               ,FNAME            IN  VARCHAR2                   
                               ,THREAD           IN  NUMBER                     
                               ,SEQUENCE         IN  NUMBER                     
                               ,RESETLOGS_CHANGE IN  NUMBER                     
                               ,FIRST_CHANGE     IN  NUMBER                     
                               ,BLKSIZE          IN  NUMBER                     
                               ,SIGNAL           IN  BINARY_INTEGER             
                               ,TERMINAL         IN  BINARY_INTEGER             
                               ,FOREIGNAL        IN  BINARY_INTEGER)            
                               RETURN BINARY_INTEGER IS                         
        OUTPUT BINARY_INTEGER;                                                  
        INPUT_FNAME             VARCHAR2(513)   NOT NULL := ' ';                
    BEGIN                                                                       
        ICDSTART(65, CHKEVENTS=>TRUE);                                          
        INPUT_FNAME := FNAME;                                                   
        OUTPUT := KRBIVAL('V', RECID, STAMP, FNAME, THREAD, SEQUENCE,           
                          RESETLOGS_CHANGE, FIRST_CHANGE, BLKSIZE, SIGNAL, 0,   
                          TERMINAL, FOREIGNAL);                                 
        ICDFINISH;                                                              
        RETURN OUTPUT;                                                          
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIPRM(PARMID IN BINARY_INTEGER,                                    
                   PARMNO IN BINARY_INTEGER DEFAULT NULL) RETURN VARCHAR2;      
  PRAGMA INTERFACE (C, KRBIPRM);                                                
                                                                                
  FUNCTION GETPARM(PARMID IN BINARY_INTEGER,                                    
                   PARMNO IN BINARY_INTEGER DEFAULT NULL) RETURN VARCHAR2 IS    
        OUTPUT VARCHAR2(512);                                                   
  BEGIN                                                                         
        ICDSTART(66);                                                           
        OUTPUT := KRBIPRM(PARMID, PARMNO);                                      
        ICDFINISH;                                                              
        RETURN OUTPUT;                                                          
  EXCEPTION                                                                     
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICKPT(CKP_SCN OUT NUMBER                                         
                   ,HIGH_CP_RECID OUT NUMBER                                    
                   ,HIGH_RT_RECID OUT NUMBER                                    
                   ,HIGH_LE_RECID OUT NUMBER                                    
                   ,HIGH_FE_RECID OUT NUMBER                                    
                   ,HIGH_FN_RECID OUT NUMBER                                    
                   ,HIGH_TS_RECID OUT NUMBER                                    
                   ,HIGH_R1_RECID OUT NUMBER                                    
                   ,HIGH_R2_RECID OUT NUMBER                                    
                   ,HIGH_LH_RECID OUT NUMBER                                    
                   ,HIGH_OR_RECID OUT NUMBER                                    
                   ,HIGH_AL_RECID OUT NUMBER                                    
                   ,HIGH_BS_RECID OUT NUMBER                                    
                   ,HIGH_BP_RECID OUT NUMBER                                    
                   ,HIGH_BF_RECID OUT NUMBER                                    
                   ,HIGH_BL_RECID OUT NUMBER                                    
                   ,HIGH_DC_RECID OUT NUMBER                                    
                   ,HIGH_FC_RECID OUT NUMBER                                    
                   ,HIGH_CC_RECID OUT NUMBER                                    
                   ,HIGH_DL_RECID OUT NUMBER                                    
                   ,HIGH_R3_RECID OUT NUMBER                                    
                   ,HIGH_R4_RECID OUT NUMBER                                    
                   );                                                           
  PRAGMA INTERFACE (C, KRBICKPT);                                               
                                                                                
  PROCEDURE GETCKPT(CKP_SCN OUT NUMBER                                          
                   ,HIGH_CP_RECID OUT NUMBER                                    
                   ,HIGH_RT_RECID OUT NUMBER                                    
                   ,HIGH_LE_RECID OUT NUMBER                                    
                   ,HIGH_FE_RECID OUT NUMBER                                    
                   ,HIGH_FN_RECID OUT NUMBER                                    
                   ,HIGH_TS_RECID OUT NUMBER                                    
                   ,HIGH_R1_RECID OUT NUMBER                                    
                   ,HIGH_RM_RECID OUT NUMBER                                    
                   ,HIGH_LH_RECID OUT NUMBER                                    
                   ,HIGH_OR_RECID OUT NUMBER                                    
                   ,HIGH_AL_RECID OUT NUMBER                                    
                   ,HIGH_BS_RECID OUT NUMBER                                    
                   ,HIGH_BP_RECID OUT NUMBER                                    
                   ,HIGH_BF_RECID OUT NUMBER                                    
                   ,HIGH_BL_RECID OUT NUMBER                                    
                   ,HIGH_DC_RECID OUT NUMBER                                    
                   ,HIGH_FC_RECID OUT NUMBER                                    
                   ,HIGH_CC_RECID OUT NUMBER                                    
                   ,HIGH_DL_RECID OUT NUMBER                                    
                   ,HIGH_R3_RECID OUT NUMBER                                    
                   ,HIGH_R4_RECID OUT NUMBER                                    
                   ) IS                                                         
  BEGIN                                                                         
        ICDSTART(67);                                                           
        KRBICKPT(CKP_SCN                                                        
                   ,HIGH_CP_RECID                                               
                   ,HIGH_RT_RECID                                               
                   ,HIGH_LE_RECID                                               
                   ,HIGH_FE_RECID                                               
                   ,HIGH_FN_RECID                                               
                   ,HIGH_TS_RECID                                               
                   ,HIGH_R1_RECID                                               
                   ,HIGH_RM_RECID                                               
                   ,HIGH_LH_RECID                                               
                   ,HIGH_OR_RECID                                               
                   ,HIGH_AL_RECID                                               
                   ,HIGH_BS_RECID                                               
                   ,HIGH_BP_RECID                                               
                   ,HIGH_BF_RECID                                               
                   ,HIGH_BL_RECID                                               
                   ,HIGH_DC_RECID                                               
                   ,HIGH_FC_RECID                                               
                   ,HIGH_CC_RECID                                               
                   ,HIGH_DL_RECID                                               
                   ,HIGH_R3_RECID                                               
                   ,HIGH_R4_RECID                                               
                );                                                              
        ICDFINISH;                                                              
  EXCEPTION                                                                     
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
  FUNCTION GETCKPTSCN RETURN NUMBER IS                                          
        CKP_SCN       NUMBER;                                                   
        HIGH_CP_RECID NUMBER;                                                   
        HIGH_RT_RECID NUMBER;                                                   
        HIGH_LE_RECID NUMBER;                                                   
        HIGH_FE_RECID NUMBER;                                                   
        HIGH_FN_RECID NUMBER;                                                   
        HIGH_TS_RECID NUMBER;                                                   
        HIGH_R1_RECID NUMBER;                                                   
        HIGH_RM_RECID NUMBER;                                                   
        HIGH_LH_RECID NUMBER;                                                   
        HIGH_OR_RECID NUMBER;                                                   
        HIGH_AL_RECID NUMBER;                                                   
        HIGH_BS_RECID NUMBER;                                                   
        HIGH_BP_RECID NUMBER;                                                   
        HIGH_BF_RECID NUMBER;                                                   
        HIGH_BL_RECID NUMBER;                                                   
        HIGH_DC_RECID NUMBER;                                                   
        HIGH_FC_RECID NUMBER;                                                   
        HIGH_CC_RECID NUMBER;                                                   
        HIGH_DL_RECID NUMBER;                                                   
        HIGH_R3_RECID NUMBER;                                                   
        HIGH_R4_RECID NUMBER;                                                   
  BEGIN                                                                         
     GETCKPT(CKP_SCN, HIGH_CP_RECID, HIGH_RT_RECID, HIGH_LE_RECID,              
             HIGH_FE_RECID, HIGH_FN_RECID, HIGH_TS_RECID, HIGH_R1_RECID,        
             HIGH_RM_RECID, HIGH_LH_RECID, HIGH_OR_RECID, HIGH_AL_RECID,        
             HIGH_BS_RECID, HIGH_BP_RECID, HIGH_BF_RECID, HIGH_BL_RECID,        
             HIGH_DC_RECID, HIGH_FC_RECID, HIGH_CC_RECID, HIGH_DL_RECID,        
             HIGH_R3_RECID, HIGH_R4_RECID);                                     
     RETURN CKP_SCN;                                                            
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICMUS( ISSTBY          IN BOOLEAN                                
                     ,SOURCE_DBUNAME  IN VARCHAR2                               
                     ,DEST_CS         IN VARCHAR2                               
                     ,SOURCE_CS       IN VARCHAR2                               
                     ,FOR_SYNC        IN BOOLEAN);                              
  PRAGMA INTERFACE (C, KRBICMUS);                                               
                                                                                
                                                                                
  PROCEDURE CFILEMAKEANDUSESNAPSHOT IS                                          
    BEGIN                                                                       
        CFILEMAKEANDUSESNAPSHOT(FALSE);                                         
    END;                                                                        
                                                                                
  PROCEDURE CFILEMAKEANDUSESNAPSHOT(ISSTBY     IN BOOLEAN)   IS                 
    BEGIN                                                                       
        CFILEMAKEANDUSESNAPSHOT(ISSTBY, NULL, NULL, NULL, FALSE);               
    END;                                                                        
                                                                                
                                                                                
  PROCEDURE CFILEMAKEANDUSESNAPSHOT( ISSTBY         IN  BOOLEAN                 
                                    ,SOURCE_DBUNAME IN  VARCHAR2                
                                    ,DEST_CS        IN  VARCHAR2                
                                    ,SOURCE_CS      IN  VARCHAR2                
                                    ,FOR_RESYNC     IN  BOOLEAN) IS             
    BEGIN                                                                       
        ICDSTART(68, CHKEVENTS=>TRUE);                                          
        KRBICMUS(ISSTBY, SOURCE_DBUNAME, DEST_CS, SOURCE_CS, FOR_RESYNC);       
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PRAGMA INTERFACE (C, KRBISLP);                                                
                                                                                
  PROCEDURE SLEEP(SECS IN BINARY_INTEGER) IS                                    
    BEGIN                                                                       
      ICDSTART(69);                                                             
      KRBISLP(SECS);                                                            
      ICDFINISH;                                                                
    EXCEPTION                                                                   
      WHEN OTHERS THEN                                                          
      ICDFINISH;                                                                
      RAISE;                                                                    
    END;                                                                        
                                                                                
                                                                                
                                                                                
  FUNCTION CHECKFILENAME(NAME IN VARCHAR2) RETURN NUMBER IS                     
     RET    NUMBER := 0;                                                        
     PARMNO NUMBER := 1;                                                        
     CFNAME VARCHAR2(1024);                                                     
  BEGIN                                                                         
    ICDSTART(143);                                                              
    BEGIN                                                                       
      SELECT 1 INTO RET FROM DUAL WHERE CHECKFILENAME.NAME IN                   
        (SELECT FN.FNNAM FROM X$KCCFN FN                                        
          WHERE BITAND(FN.FNFLG, 4) != 4                                        
            AND FN.FNTYP IN (3, 4, 7, 24, 200)                                  
            AND FNNAM IS NOT NULL);                                             
    EXCEPTION                                                                   
      WHEN NO_DATA_FOUND THEN NULL;                                             
    END;                                                                        
                                                                                
                                                                                
    IF RET <> 1 THEN                                                            
      LOOP                                                                      
        CFNAME := KRBIPRM(1, PARMNO);                                           
        IF CFNAME IS NULL THEN EXIT; END IF;                                    
        IF CFNAME = NAME THEN                                                   
          RET := 1;                                                             
          EXIT;                                                                 
        END IF;                                                                 
        PARMNO := PARMNO + 1;                                                   
      END LOOP;                                                                 
    END IF;                                                                     
    ICDFINISH;                                                                  
    RETURN RET;                                                                 
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE SET_CLIENT_INFO(CLIENT_INFO IN VARCHAR2) IS                         
  BEGIN                                                                         
    ICDSTART(144);                                                              
    SYS.DBMS_APPLICATION_INFO.SET_CLIENT_INFO(CLIENT_INFO);                     
    ICDFINISH;                                                                  
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISTCS(CHARSET_NAME IN VARCHAR2);                                 
  PRAGMA INTERFACE (C, KRBISTCS);                                               
                                                                                
  PROCEDURE SET_CHARSET(CHARSET_NAME IN VARCHAR2) IS                            
  BEGIN                                                                         
     ICDSTART(70);                                                              
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
     CHECK_VERSION(8,0,4, 'dbms_backup_restore');                               
     KRBISTCS(CHARSET_NAME);                                                    
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
  PROCEDURE CHECK_VERSION(VERSION IN NUMBER,                                    
                          RELEASE IN NUMBER,                                    
                          UPDAT   IN NUMBER,                                    
                          PKG_NAME IN VARCHAR2) IS                              
    V NUMBER;                                                                   
    R NUMBER;                                                                   
    U NUMBER;                                                                   
    VSN VARCHAR2(20);                                                           
  BEGIN                                                                         
     SELECT VERSION INTO VSN FROM V$INSTANCE;                                   
     V := TO_NUMBER(SUBSTR(VSN, 1, INSTR(VSN,'.',1,1)-1));                      
     R := TO_NUMBER(SUBSTR(VSN, 1+INSTR(VSN,'.',1,1),                           
                           INSTR(VSN,'.',1,2)-INSTR(VSN,'.',1,1)-1));           
     U := TO_NUMBER(SUBSTR(VSN, 1+INSTR(VSN,'.',1,2),                           
                           INSTR(VSN,'.',1,3)-INSTR(VSN,'.',1,2)-1));           
     IF (V > VERSION) THEN                                                      
       RETURN;                                                                  
     ELSIF (V = VERSION) THEN                                                   
       IF (R > RELEASE) THEN                                                    
         RETURN;                                                                
       ELSIF (R = RELEASE) THEN                                                 
         IF (U >= UPDAT) THEN                                                   
           RETURN;                                                              
         END IF;                                                                
       END IF;                                                                  
     END IF;                                                                    
                                                                                
     SYS.DBMS_SYS_ERROR.RAISE_SYSTEM_ERROR(-29350, VSN, PKG_NAME,               
       TO_CHAR(VERSION)||'.'||TO_CHAR(RELEASE)||'.'||TO_CHAR(UPDAT));           
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPBB(TAG           IN   VARCHAR2        DEFAULT NULL             
                   ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE            
                   ,MEDIA_POOL    IN   BINARY_INTEGER  DEFAULT 0                
                   ,SET_STAMP     OUT  NUMBER                                   
                   ,SET_COUNT     OUT  NUMBER                                   
                   ,KEEP_OPTIONS  IN   BINARY_INTEGER                           
                   ,KEEP_UNTIL    IN   NUMBER);                                 
  PRAGMA INTERFACE (C, KRBIPBB);                                                
                                                                                
  PROCEDURE                                                                     
    PROXYBEGINBACKUP(TAG           IN   VARCHAR2        DEFAULT NULL            
                    ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE           
                    ,MEDIA_POOL    IN   BINARY_INTEGER  DEFAULT 0               
                    ,SET_STAMP     OUT  NUMBER                                  
                    ,SET_COUNT     OUT  NUMBER)                                 
  IS                                                                            
  BEGIN                                                                         
     PROXYBEGINBACKUP(TAG, INCREMENTAL, MEDIA_POOL,                             
                      SET_STAMP, SET_COUNT, 0, 0);                              
  END;                                                                          
                                                                                
  PROCEDURE                                                                     
    PROXYBEGINBACKUP(TAG           IN   VARCHAR2        DEFAULT NULL            
                    ,INCREMENTAL   IN   BOOLEAN         DEFAULT FALSE           
                    ,MEDIA_POOL    IN   BINARY_INTEGER  DEFAULT 0               
                    ,SET_STAMP     OUT  NUMBER                                  
                    ,SET_COUNT     OUT  NUMBER                                  
                    ,KEEP_OPTIONS  IN   BINARY_INTEGER                          
                    ,KEEP_UNTIL    IN   NUMBER )                                
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(71, CHKEVENTS=>TRUE);                                             
     KRBIPBB(TAG, INCREMENTAL, MEDIA_POOL, SET_STAMP,                           
             SET_COUNT, KEEP_OPTIONS, KEEP_UNTIL);                              
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPBR( DESTINATION IN VARCHAR2 DEFAULT NULL                       
                    ,CLEANUP    IN BOOLEAN);                                    
  PRAGMA INTERFACE (C, KRBIPBR);                                                
                                                                                
  PROCEDURE PROXYBEGINRESTORE(DESTINATION IN VARCHAR2 DEFAULT NULL)             
  IS                                                                            
  BEGIN                                                                         
     PROXYBEGINRESTORE(DESTINATION, TRUE);                                      
  END;                                                                          
                                                                                
  PROCEDURE PROXYBEGINRESTORE( DESTINATION IN VARCHAR2 DEFAULT NULL             
                              ,CLEANUP    IN BOOLEAN)                           
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(72, CHKEVENTS=>TRUE);                                             
     KRBIPBR(DESTINATION, CLEANUP);                                             
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPBDF(FILE# IN BINARY_INTEGER,                                   
                     HANDLE IN VARCHAR2);                                       
  PRAGMA INTERFACE (C, KRBIPBDF);                                               
                                                                                
  PROCEDURE                                                                     
    PROXYBACKUPDATAFILE(FILE# IN BINARY_INTEGER,                                
                        HANDLE IN VARCHAR2)                                     
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(73);                                                              
     KRBIPBDF(FILE#, HANDLE);                                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPBDC(COPY_RECID IN NUMBER,                                      
                     COPY_STAMP IN NUMBER,                                      
                     HANDLE IN VARCHAR2);                                       
                                                                                
  PRAGMA INTERFACE (C, KRBIPBDC);                                               
                                                                                
  PROCEDURE                                                                     
    PROXYBACKUPDATAFILECOPY(COPY_RECID IN NUMBER,                               
                            COPY_STAMP IN NUMBER,                               
                            HANDLE IN VARCHAR2)                                 
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(74);                                                              
     KRBIPBDC(COPY_RECID, COPY_STAMP, HANDLE);                                  
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPBCF(NAME IN VARCHAR2 DEFAULT NULL, HANDLE IN VARCHAR2);        
  PRAGMA INTERFACE (C, KRBIPBCF);                                               
                                                                                
  PROCEDURE PROXYBACKUPCONTROLFILE(NAME IN VARCHAR2 DEFAULT NULL,               
                                   HANDLE IN VARCHAR2)                          
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(75);                                                              
     KRBIPBCF(NAME, HANDLE);                                                    
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPBA(ARCH_RECID IN NUMBER,                                       
                    ARCH_STAMP IN NUMBER,                                       
                    HANDLE IN VARCHAR2);                                        
                                                                                
  PRAGMA INTERFACE (C, KRBIPBA);                                                
                                                                                
  PROCEDURE                                                                     
    PROXYBACKUPARCHIVEDLOG(ARCH_RECID IN NUMBER,                                
                           ARCH_STAMP IN NUMBER,                                
                           HANDLE IN VARCHAR2)                                  
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(76);                                                              
     KRBIPBA(ARCH_RECID, ARCH_STAMP, HANDLE);                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPRDF(HANDLE    IN VARCHAR2                                      
                    ,FILE#     IN BINARY_INTEGER                                
                    ,TONAME    IN VARCHAR2 DEFAULT NULL                         
                    ,TSNAME    IN VARCHAR2                                      
                    ,BLKSIZE   IN BINARY_INTEGER                                
                    ,BLOCKS    IN NUMBER);                                      
                                                                                
  PRAGMA INTERFACE (C, KRBIPRDF);                                               
                                                                                
  PROCEDURE                                                                     
    PROXYRESTOREDATAFILE(HANDLE IN VARCHAR2,                                    
                         FILE# IN BINARY_INTEGER,                               
                         TONAME IN VARCHAR2 DEFAULT NULL)                       
  IS                                                                            
  BEGIN                                                                         
     PROXYRESTOREDATAFILE(HANDLE, FILE#, TONAME, TO_CHAR(NULL), 0, 0);          
  END;                                                                          
                                                                                
  PROCEDURE                                                                     
    PROXYRESTOREDATAFILE(HANDLE    IN VARCHAR2,                                 
                         FILE#     IN BINARY_INTEGER,                           
                         TONAME    IN VARCHAR2 DEFAULT NULL,                    
                         TSNAME    IN VARCHAR2,                                 
                         BLKSIZE   IN BINARY_INTEGER,                           
                         BLOCKS    IN NUMBER)                                   
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(77);                                                              
     KRBIPRDF(HANDLE, FILE#, TONAME, TSNAME, BLKSIZE, BLOCKS);                  
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPRCF(HANDLE  IN VARCHAR2,                                       
                     TONAME  IN VARCHAR2,                                       
                     BLKSIZE IN BINARY_INTEGER,                                 
                     BLOCKS  IN NUMBER);                                        
  PRAGMA INTERFACE (C, KRBIPRCF);                                               
                                                                                
  PROCEDURE PROXYRESTORECONTROLFILE(HANDLE  IN VARCHAR2,                        
                                    TONAME  IN VARCHAR2)                        
  IS                                                                            
  BEGIN                                                                         
     PROXYRESTORECONTROLFILE(HANDLE, TONAME, 0, 0);                             
  END;                                                                          
                                                                                
  PROCEDURE PROXYRESTORECONTROLFILE(HANDLE  IN VARCHAR2,                        
                                    TONAME  IN VARCHAR2,                        
                                    BLKSIZE IN BINARY_INTEGER,                  
                                    BLOCKS  IN NUMBER)                          
  IS                                                                            
    BEGIN                                                                       
        ICDSTART(78);                                                           
        KRBIPRCF(HANDLE, TONAME, BLKSIZE, BLOCKS);                              
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPRA(HANDLE       IN VARCHAR2,                                   
                    THREAD       IN BINARY_INTEGER,                             
                    SEQUENCE     IN NUMBER,                                     
                    RESETLOGS_ID IN NUMBER,                                     
                    BLKSIZE      IN BINARY_INTEGER,                             
                    BLOCKS       IN NUMBER);                                    
                                                                                
  PRAGMA INTERFACE (C, KRBIPRA);                                                
                                                                                
  PROCEDURE                                                                     
    PROXYRESTOREARCHIVEDLOG(HANDLE      IN VARCHAR2,                            
                            THREAD      IN BINARY_INTEGER,                      
                            SEQUENCE    IN NUMBER)                              
  IS                                                                            
  BEGIN                                                                         
     PROXYRESTOREARCHIVEDLOG(HANDLE, THREAD, SEQUENCE, NULL, 0 ,0);             
  END;                                                                          
                                                                                
  PROCEDURE                                                                     
    PROXYRESTOREARCHIVEDLOG(HANDLE        IN VARCHAR2,                          
                            THREAD        IN BINARY_INTEGER,                    
                            SEQUENCE      IN NUMBER,                            
                            RESETLOGS_ID  IN NUMBER,                            
                            BLKSIZE       IN BINARY_INTEGER,                    
                            BLOCKS        IN NUMBER)                            
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(79);                                                              
     KRBIPRA(HANDLE, THREAD, SEQUENCE, RESETLOGS_ID, BLKSIZE, BLOCKS);          
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPGO;                                                            
                                                                                
  PRAGMA INTERFACE (C, KRBIPGO);                                                
                                                                                
  PROCEDURE                                                                     
    PROXYGO                                                                     
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(80);                                                              
     KRBIPGO;                                                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIPQB(NAME IN VARCHAR2) RETURN BINARY_INTEGER;                     
  PRAGMA INTERFACE (C, KRBIPQB);                                                
                                                                                
  FUNCTION                                                                      
    PROXYQUERYBACKUP(NAME IN VARCHAR2) RETURN BINARY_INTEGER                    
  IS                                                                            
     RET BINARY_INTEGER;                                                        
  BEGIN                                                                         
     ICDSTART(81);                                                              
     IF NAME IS NULL THEN                                                       
        KRBIRERR(19864, 'Datafile name to backup is NULL');                     
     END IF;                                                                    
     RET := KRBIPQB(NAME);                                                      
     ICDFINISH;                                                                 
     RETURN RET;                                                                
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIPQR(HANDLE IN VARCHAR2,                                          
                   TONAME IN VARCHAR2) RETURN BINARY_INTEGER;                   
  PRAGMA INTERFACE (C, KRBIPQR);                                                
                                                                                
  FUNCTION                                                                      
    PROXYQUERYRESTORE(HANDLE IN VARCHAR2,                                       
                      TONAME IN VARCHAR2) RETURN BINARY_INTEGER                 
  IS                                                                            
     RET BINARY_INTEGER;                                                        
  BEGIN                                                                         
     ICDSTART(82);                                                              
     IF HANDLE IS NULL THEN                                                     
        KRBIRERR(19864, 'Proxy handle is NULL');                                
     END IF;                                                                    
     IF TONAME IS NULL THEN                                                     
        KRBIRERR(19864, 'Datafile name to restore is NULL');                    
     END IF;                                                                    
     RET := KRBIPQR(HANDLE, TONAME);                                            
     ICDFINISH;                                                                 
     RETURN RET;                                                                
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPCN;                                                            
  PRAGMA INTERFACE (C, KRBIPCN);                                                
                                                                                
  PROCEDURE                                                                     
    PROXYCANCEL                                                                 
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(83);                                                              
     KRBIPCN;                                                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPDL(OP            IN  VARCHAR2                                  
                   ,RECID         IN  NUMBER                                    
                   ,STAMP         IN  NUMBER                                    
                   ,HANDLE        IN  VARCHAR2                                  
                   ,PARAMS        IN  VARCHAR2 DEFAULT NULL                     
                   ,KEEP_OPTIONS  IN  BINARY_INTEGER                            
                   ,KEEP_UNTIL    IN  NUMBER                                    
                   ,FORCE         IN  BINARY_INTEGER);                          
  PRAGMA INTERFACE (C, KRBIPDL);                                                
                                                                                
  PROCEDURE PROXYDELETE(RECID      IN  NUMBER                                   
                       ,STAMP      IN  NUMBER                                   
                       ,HANDLE     IN  VARCHAR2                                 
                       ,PARAMS     IN  VARCHAR2 DEFAULT NULL) IS                
  BEGIN                                                                         
     PROXYCHANGE(RECID, STAMP, HANDLE, 'D', PARAMS, 0, 0);                      
  END;                                                                          
                                                                                
  PROCEDURE PROXYDELETE(RECID      IN  NUMBER                                   
                       ,STAMP      IN  NUMBER                                   
                       ,HANDLE     IN  VARCHAR2                                 
                       ,PARAMS     IN  VARCHAR2 DEFAULT NULL                    
                       ,FORCE      IN  BINARY_INTEGER) IS                       
  BEGIN                                                                         
     PROXYCHANGE(RECID, STAMP, HANDLE, 'D', PARAMS, 0, 0, FORCE);               
  END;                                                                          
                                                                                
  PROCEDURE PROXYCHANGE(RECID      IN  NUMBER                                   
                       ,STAMP      IN  NUMBER                                   
                       ,HANDLE     IN  VARCHAR2                                 
                       ,STATUS     IN  VARCHAR2                                 
                       ,PARAMS     IN  VARCHAR2 DEFAULT NULL) IS                
  BEGIN                                                                         
     PROXYCHANGE(RECID, STAMP, HANDLE, STATUS, PARAMS, 0, 0);                   
  END;                                                                          
                                                                                
  PROCEDURE PROXYCHANGE(RECID         IN  NUMBER                                
                       ,STAMP         IN  NUMBER                                
                       ,HANDLE        IN  VARCHAR2                              
                       ,STATUS        IN  VARCHAR2                              
                       ,PARAMS        IN  VARCHAR2 DEFAULT NULL                 
                       ,KEEP_OPTIONS  IN  BINARY_INTEGER                        
                       ,KEEP_UNTIL    IN  NUMBER) IS                            
  BEGIN                                                                         
     PROXYCHANGE(RECID, STAMP, HANDLE, STATUS, PARAMS, KEEP_OPTIONS,            
                 KEEP_UNTIL, 0);                                                
  END;                                                                          
                                                                                
  PROCEDURE PROXYCHANGE(RECID         IN  NUMBER                                
                       ,STAMP         IN  NUMBER                                
                       ,HANDLE        IN  VARCHAR2                              
                       ,STATUS        IN  VARCHAR2                              
                       ,PARAMS        IN  VARCHAR2 DEFAULT NULL                 
                       ,KEEP_OPTIONS  IN  BINARY_INTEGER                        
                       ,KEEP_UNTIL    IN  NUMBER                                
                       ,FORCE         IN  BINARY_INTEGER) IS                    
  BEGIN                                                                         
     ICDSTART(84);                                                              
     IF STATUS IS NULL THEN                                                     
        KRBIRERR(19864, 'Missing proxy operation');                             
     END IF;                                                                    
                                                                                
     IF LENGTH(STATUS) > 1 THEN                                                 
        KRBIRERR(19864, 'Invalid proxy operation length: '||                    
                 TO_CHAR(LENGTH(STATUS)));                                      
     END IF;                                                                    
     KRBIPDL(STATUS, RECID, STAMP, HANDLE, PARAMS, KEEP_OPTIONS,                
             KEEP_UNTIL, FORCE);                                                
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIPVL(OP           IN  VARCHAR2                                    
                  ,RECID        IN  NUMBER                                      
                  ,STAMP        IN  NUMBER                                      
                  ,HANDLE       IN  VARCHAR2                                    
                  ,PARAMS       IN  VARCHAR2 DEFAULT NULL                       
                  ,KEEP_OPTIONS IN  BINARY_INTEGER                              
                  ,KEEP_UNTIL   IN  NUMBER                                      
                  ,FORCE        IN    BINARY_INTEGER)                           
    RETURN BINARY_INTEGER;                                                      
  PRAGMA INTERFACE (C, KRBIPVL);                                                
                                                                                
  FUNCTION PROXYVALIDATE(RECID      IN  NUMBER                                  
                        ,STAMP      IN  NUMBER                                  
                        ,HANDLE     IN  VARCHAR2                                
                        ,PARAMS     IN  VARCHAR2 DEFAULT NULL)                  
    RETURN BINARY_INTEGER IS                                                    
    OUTPUT BINARY_INTEGER;                                                      
  BEGIN                                                                         
     ICDSTART(85);                                                              
     OUTPUT := KRBIPVL('V', RECID, STAMP, HANDLE, PARAMS, 0, 0, 0);             
     IF BITAND(OUTPUT, VALIDATE_FILE_DIFFERENT) = 0 THEN                        
        KRBIPDL('A', RECID, STAMP, HANDLE, PARAMS, 0, 0, 0);                    
     ELSE                                                                       
        KRBIPDL('X', RECID, STAMP, HANDLE, PARAMS, 0, 0, 0);                    
     END IF;                                                                    
     ICDFINISH;                                                                 
     RETURN OUTPUT;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
  FUNCTION PROXYVALONLY(RECID      IN  NUMBER                                   
                        ,STAMP      IN  NUMBER                                  
                        ,HANDLE     IN  VARCHAR2                                
                        ,PARAMS     IN  VARCHAR2 DEFAULT NULL)                  
    RETURN BINARY_INTEGER IS                                                    
    OUTPUT BINARY_INTEGER;                                                      
  BEGIN                                                                         
     ICDSTART(86, CHKEVENTS=>TRUE);                                             
     OUTPUT := KRBIPVL('V', RECID, STAMP, HANDLE, PARAMS, 0, 0, 0);             
     ICDFINISH;                                                                 
     RETURN OUTPUT;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIMXI(MLOGF      OUT  BINARY_INTEGER                              
                   ,MLOGM      OUT  BINARY_INTEGER                              
                   ,MDATF      OUT  BINARY_INTEGER                              
                   ,MINST      OUT  BINARY_INTEGER                              
                   ,MLOGH      OUT  BINARY_INTEGER                              
                   ,CHSET      OUT  VARCHAR2);                                  
  PRAGMA INTERFACE (C, KRBIMXI);                                                
                                                                                
  PROCEDURE GETMAXINFO(MLOGF      OUT  BINARY_INTEGER                           
                      ,MLOGM      OUT  BINARY_INTEGER                           
                      ,MDATF      OUT  BINARY_INTEGER                           
                      ,MINST      OUT  BINARY_INTEGER                           
                      ,MLOGH      OUT  BINARY_INTEGER                           
                      ,CHSET      OUT  VARCHAR2) IS                             
  BEGIN                                                                         
     ICDSTART(87);                                                              
     KRBIMXI(MLOGF, MLOGM, MDATF, MINST, MLOGH, CHSET);                         
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIZERF(FNO       IN   BINARY_INTEGER);                            
                                                                                
  PRAGMA INTERFACE (C, KRBIZERF);                                               
                                                                                
  PROCEDURE ZERODBID(FNO       IN   BINARY_INTEGER) IS                          
                                                                                
  BEGIN                                                                         
     ICDSTART(88);                                                              
     IF FNO IS NULL THEN                                                        
        KRBIRERR(19864, 'Null file number not allowed');                        
     END IF;                                                                    
     KRBIZERF(FNO);                                                             
     ICDFINISH;                                                                 
                                                                                
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIVTS( TSID         IN   BINARY_INTEGER                           
                    ,CURRSCN     OUT  NUMBER  ) ;                               
  PRAGMA INTERFACE (C, KRBIVTS);                                                
                                                                                
  FUNCTION VALIDATETABLESPACE( TSID        IN BINARY_INTEGER                    
                              ,CSCN        IN NUMBER )                          
      RETURN BINARY_INTEGER IS                                                  
                                                                                
      RET       BINARY_INTEGER;                                                 
      CURRSCN   NUMBER;                                                         
  BEGIN                                                                         
     ICDSTART(89);                                                              
     KRBIVTS(TSID, CURRSCN);                                                    
     IF (CURRSCN > CSCN) THEN                                                   
         RET := 0;                                                              
     ELSE                                                                       
         RET := 1;                                                              
     END IF;                                                                    
     ICDFINISH;                                                                 
     RETURN RET;                                                                
                                                                                
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
                                                                                
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRAN;                                                            
  PRAGMA INTERFACE (C, KRBIRAN);                                                
                                                                                
  PROCEDURE RENORMALIZEALLFILENAMES IS                                          
  BEGIN                                                                         
     ICDSTART(90);                                                              
     KRBIRAN;                                                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIGPN(FORMAT     IN VARCHAR2                                       
                   ,PNO       IN NUMBER                                         
                   ,BCOUNT    IN NUMBER                                         
                   ,BSTAMP    IN NUMBER                                         
                   ,COPYNO    IN NUMBER                                         
                   ,DEVTYPE   IN VARCHAR2                                       
                   ,YEAR      IN BINARY_INTEGER                                 
                   ,MONTH     IN BINARY_INTEGER                                 
                   ,DAY       IN BINARY_INTEGER                                 
                   ,DBID      IN NUMBER                                         
                   ,NDBNAME   IN VARCHAR2                                       
                   ,CFSEQ     IN NUMBER                                         
                   ,FILENO    IN NUMBER                                         
                   ,TSNAME    IN VARCHAR2                                       
                   ,LOGSEQ    IN VARCHAR2                                       
                   ,LOGTHR    IN NUMBER                                         
                   ,IMAGCP    IN BOOLEAN                                        
                   ,SAVEPNAME IN BOOLEAN                                        
                   ,FNAME     IN VARCHAR2                                       
                   ,FORCNVRT  IN BOOLEAN)                                       
                   RETURN VARCHAR2;                                             
                                                                                
  PRAGMA INTERFACE (C, KRBIGPN);                                                
                                                                                
                                                                                
  FUNCTION GENPIECENAME(PNO        IN NUMBER                                    
                        ,SET_COUNT IN NUMBER                                    
                        ,SET_STAMP IN NUMBER                                    
                        ,FORMAT    IN VARCHAR2                                  
                        ,COPYNO    IN NUMBER                                    
                        ,DEVTYPE   IN VARCHAR2                                  
                        ,YEAR      IN VARCHAR2                                  
                        ,MONTH     IN VARCHAR2                                  
                        ,DAY       IN VARCHAR2                                  
                        ,DBID      IN VARCHAR2                                  
                        ,NDBNAME   IN VARCHAR2                                  
                        ,PDBNAME   IN VARCHAR2                                  
                        ,CFSEQ     IN NUMBER)                                   
                        RETURN VARCHAR2 IS                                      
     NDBID    NUMBER := TO_NUMBER(DBID);                                        
     IYEAR    BINARY_INTEGER NOT NULL := TO_NUMBER(YEAR);                       
     IMONTH   BINARY_INTEGER NOT NULL := TO_NUMBER(MONTH);                      
     IDAY     BINARY_INTEGER NOT NULL := TO_NUMBER(DAY);                        
     DBNAME   VARCHAR2(30);                                                     
BEGIN                                                                           
                                                                                
    IF DBID = '-1' THEN                                                         
       NDBID := TO_NUMBER(NULL);                                                
    END IF;                                                                     
                                                                                
                                                                                
                                                                                
    IF NDBNAME = 'N/A' THEN                                                     
       DBNAME := TO_CHAR(NULL);                                                 
    ELSE                                                                        
       DBNAME := NDBNAME;                                                       
    END IF;                                                                     
                                                                                
    RETURN GENPIECENAME(PNO => PNO,                                             
                        SET_COUNT => SET_COUNT,                                 
                        SET_STAMP => SET_STAMP,                                 
                        FORMAT => FORMAT,                                       
                        COPYNO => COPYNO,                                       
                        DEVTYPE => DEVTYPE,                                     
                        YEAR => IYEAR,                                          
                        MONTH => IMONTH,                                        
                        DAY => IDAY,                                            
                        DBID => NDBID,                                          
                        NDBNAME => DBNAME,                                      
                        CFSEQ => CFSEQ,                                         
                        FILENO => TO_NUMBER(NULL),                              
                        TSNAME => TO_CHAR(NULL),                                
                        LOGSEQ => TO_CHAR(NULL),                                
                        LOGTHR => TO_NUMBER(NULL),                              
                        IMAGCP => FALSE);                                       
END;                                                                            
                                                                                
                                                                                
  FUNCTION GENPIECENAME(PNO        IN NUMBER                                    
                        ,SET_COUNT IN NUMBER                                    
                        ,SET_STAMP IN NUMBER                                    
                        ,FORMAT    IN VARCHAR2                                  
                        ,COPYNO    IN NUMBER                                    
                        ,DEVTYPE   IN VARCHAR2                                  
                        ,YEAR      IN BINARY_INTEGER                            
                        ,MONTH     IN BINARY_INTEGER                            
                        ,DAY       IN BINARY_INTEGER                            
                        ,DBID      IN NUMBER                                    
                        ,NDBNAME   IN VARCHAR2                                  
                        ,CFSEQ     IN NUMBER                                    
                        ,FILENO    IN NUMBER                                    
                        ,TSNAME    IN VARCHAR2                                  
                        ,LOGSEQ    IN VARCHAR2                                  
                        ,LOGTHR    IN NUMBER                                    
                        ,IMAGCP    IN BOOLEAN)                                  
                        RETURN VARCHAR2 IS                                      
BEGIN                                                                           
                                                                                
    RETURN GENPIECENAME(PNO       => PNO,                                       
                        SET_COUNT => SET_COUNT,                                 
                        SET_STAMP => SET_STAMP,                                 
                        FORMAT    => FORMAT,                                    
                        COPYNO    => COPYNO,                                    
                        DEVTYPE   => DEVTYPE,                                   
                        YEAR      => YEAR,                                      
                        MONTH     => MONTH,                                     
                        DAY       => DAY,                                       
                        DBID      => DBID,                                      
                        NDBNAME   => NDBNAME,                                   
                        CFSEQ     => CFSEQ,                                     
                        FILENO    => FILENO,                                    
                        TSNAME    => TSNAME,                                    
                        LOGSEQ    => LOGSEQ,                                    
                        LOGTHR    => LOGTHR,                                    
                        IMAGCP    => IMAGCP,                                    
                        SAVEPNAME => FALSE,                                     
                        FNAME     => TO_CHAR(NULL),                             
                        FORCNVRT  => FALSE);                                    
END;                                                                            
                                                                                
  FUNCTION GENPIECENAME(PNO        IN NUMBER                                    
                        ,SET_COUNT IN NUMBER                                    
                        ,SET_STAMP IN NUMBER                                    
                        ,FORMAT    IN VARCHAR2                                  
                        ,COPYNO    IN NUMBER                                    
                        ,DEVTYPE   IN VARCHAR2                                  
                        ,YEAR      IN BINARY_INTEGER                            
                        ,MONTH     IN BINARY_INTEGER                            
                        ,DAY       IN BINARY_INTEGER                            
                        ,DBID      IN NUMBER                                    
                        ,NDBNAME   IN VARCHAR2                                  
                        ,CFSEQ     IN NUMBER                                    
                        ,FILENO    IN NUMBER                                    
                        ,TSNAME    IN VARCHAR2                                  
                        ,LOGSEQ    IN VARCHAR2                                  
                        ,LOGTHR    IN NUMBER                                    
                        ,IMAGCP    IN BOOLEAN                                   
                        ,SAVEPNAME IN BOOLEAN)                                  
                        RETURN VARCHAR2 IS                                      
BEGIN                                                                           
                                                                                
    RETURN GENPIECENAME(PNO       => PNO,                                       
                        SET_COUNT => SET_COUNT,                                 
                        SET_STAMP => SET_STAMP,                                 
                        FORMAT    => FORMAT,                                    
                        COPYNO    => COPYNO,                                    
                        DEVTYPE   => DEVTYPE,                                   
                        YEAR      => YEAR,                                      
                        MONTH     => MONTH,                                     
                        DAY       => DAY,                                       
                        DBID      => DBID,                                      
                        NDBNAME   => NDBNAME,                                   
                        CFSEQ     => CFSEQ,                                     
                        FILENO    => FILENO,                                    
                        TSNAME    => TSNAME,                                    
                        LOGSEQ    => LOGSEQ,                                    
                        LOGTHR    => LOGTHR,                                    
                        IMAGCP    => IMAGCP,                                    
                        SAVEPNAME => SAVEPNAME,                                 
                        FNAME     => TO_CHAR(NULL),                             
                        FORCNVRT  => TRUE);                                     
END;                                                                            
                                                                                
                                                                                
  FUNCTION GENPIECENAME(PNO        IN NUMBER                                    
                        ,SET_COUNT IN NUMBER                                    
                        ,SET_STAMP IN NUMBER                                    
                        ,FORMAT    IN VARCHAR2                                  
                        ,COPYNO    IN NUMBER                                    
                        ,DEVTYPE   IN VARCHAR2                                  
                        ,YEAR      IN BINARY_INTEGER                            
                        ,MONTH     IN BINARY_INTEGER                            
                        ,DAY       IN BINARY_INTEGER                            
                        ,DBID      IN NUMBER                                    
                        ,NDBNAME   IN VARCHAR2                                  
                        ,CFSEQ     IN NUMBER                                    
                        ,FILENO    IN NUMBER                                    
                        ,TSNAME    IN VARCHAR2                                  
                        ,LOGSEQ    IN VARCHAR2                                  
                        ,LOGTHR    IN NUMBER                                    
                        ,IMAGCP    IN BOOLEAN                                   
                        ,SAVEPNAME IN BOOLEAN                                   
                        ,FNAME     IN VARCHAR2                                  
                        ,FORCNVRT  IN BOOLEAN)                                  
                        RETURN VARCHAR2 IS                                      
     PIECENAME VARCHAR2(512) NOT NULL := 'foo';                                 
     IPNO NUMBER NOT NULL := PNO;                                               
     ISET_COUNT NUMBER NOT NULL := SET_COUNT;                                   
     ISET_STAMP NUMBER NOT NULL := SET_STAMP;                                   
     IFORMAT VARCHAR2(512) NOT NULL := FORMAT;                                  
     ICOPYNO NUMBER NOT NULL := COPYNO;                                         
     ITYPE VARCHAR2(16) NOT NULL := DEVTYPE;                                    
     IYEAR BINARY_INTEGER NOT NULL := YEAR;                                     
     IMONTH BINARY_INTEGER NOT NULL := MONTH;                                   
     IDAY BINARY_INTEGER NOT NULL := DAY;                                       
  BEGIN                                                                         
                                                                                
                                                                                
     ICDSTART(91);                                                              
     PIECENAME := KRBIGPN(IFORMAT, IPNO, SET_COUNT, SET_STAMP, ICOPYNO, ITYPE,  
                          IYEAR, IMONTH, IDAY, DBID, NDBNAME, CFSEQ,            
                          FILENO, TSNAME, LOGSEQ, LOGTHR, IMAGCP, SAVEPNAME,    
                          FNAME, FORCNVRT);                                     
     ICDFINISH;                                                                 
     RETURN PIECENAME;                                                          
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION  KRBISRM(NAME               IN  VARCHAR2,                            
                    VALUE              IN  VARCHAR2) RETURN BINARY_INTEGER;     
  PRAGMA INTERFACE (C, KRBISRM);                                                
                                                                                
  PROCEDURE KRBIDRM(CONF#              IN  BINARY_INTEGER);                     
  PRAGMA INTERFACE (C, KRBIDRM);                                                
                                                                                
  PROCEDURE KRBIRRM;                                                            
  PRAGMA INTERFACE (C, KRBIRRM);                                                
                                                                                
  FUNCTION SETCONFIG (NAME             IN  VARCHAR2,                            
                      VALUE            IN  VARCHAR2 DEFAULT NULL )              
           RETURN BINARY_INTEGER IS                                             
     RECNO          BINARY_INTEGER NOT NULL := 0;                               
  BEGIN                                                                         
     ICDSTART(92);                                                              
     IF NAME IS NULL THEN                                                       
        KRBIRERR(19864, 'Configuration name is NULL');                          
     END IF;                                                                    
     RECNO := KRBISRM(NAME, VALUE);                                             
     ICDFINISH;                                                                 
     RETURN RECNO;                                                              
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
  PROCEDURE RESETCONFIG IS                                                      
  BEGIN                                                                         
     ICDSTART(93);                                                              
     KRBIRRM;                                                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
  PROCEDURE DELETECONFIG (CONF#        IN BINARY_INTEGER ) IS                   
  BEGIN                                                                         
     ICDSTART(94);                                                              
     IF CONF# IS NULL THEN                                                      
        KRBIRERR(19864, 'Configuration number is NULL');                        
     END IF;                                                                    
     KRBIDRM(CONF#);                                                            
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIAUX( DFNUMBER  IN  BINARY_INTEGER                               
                    ,FNAME     IN  VARCHAR2);                                   
  PRAGMA INTERFACE (C, KRBIAUX);                                                
                                                                                
                                                                                
  PROCEDURE SETDATAFILEAUX( DFNUMBER  IN  BINARY_INTEGER                        
                           ,FNAME     IN  VARCHAR2 DEFAULT NULL) IS             
    BEGIN                                                                       
        ICDSTART(95);                                                           
        KRBIAUX(DFNUMBER, FNAME);                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE KRBITSAT(CODE IN BINARY_INTEGER,                                    
                     TSID  IN  BINARY_INTEGER,                                  
                     CLEAR IN  BINARY_INTEGER,                                  
                     ONOFF IN  BINARY_INTEGER);                                 
  PRAGMA INTERFACE (C, KRBITSAT);                                               
                                                                                
  PROCEDURE SETTABLESPACEEXCLUDE( TSID  IN  BINARY_INTEGER                      
                                 ,FLAG  IN  BINARY_INTEGER) IS                  
    BEGIN                                                                       
        ICDSTART(96);                                                           
        KRBITSAT(0, TSID, 0, FLAG);                                             
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBMRS( SAVE_ALL_BLOCKS   IN BOOLEAN,                             
                      SAVE_FINAL_BLOCKS IN BOOLEAN,                             
                      NOFILEUPDATE      IN BOOLEAN,                             
                      DOCLEAR           IN BOOLEAN,                             
                      FLAGS_CLEAR       IN BINARY_INTEGER );                    
  PRAGMA INTERFACE (C, KRBIBMRS);                                               
                                                                                
  PROCEDURE BMRSTART( SAVE_ALL_BLOCKS   IN BOOLEAN,                             
                      SAVE_FINAL_BLOCKS IN BOOLEAN,                             
                      NOFILEUPDATE      IN BOOLEAN )  IS                        
  BEGIN                                                                         
     BMRSTART(SAVE_ALL_BLOCKS, SAVE_FINAL_BLOCKS, NOFILEUPDATE,                 
              FALSE, 0);                                                        
  END;                                                                          
                                                                                
  PROCEDURE BMRSTART( SAVE_ALL_BLOCKS   IN BOOLEAN,                             
                      SAVE_FINAL_BLOCKS IN BOOLEAN,                             
                      NOFILEUPDATE      IN BOOLEAN,                             
                      DOCLEAR           IN BOOLEAN )  IS                        
  BEGIN                                                                         
     BMRSTART(SAVE_ALL_BLOCKS, SAVE_FINAL_BLOCKS, NOFILEUPDATE,                 
              DOCLEAR, 0);                                                      
  END;                                                                          
                                                                                
  PROCEDURE BMRSTART( SAVE_ALL_BLOCKS   IN BOOLEAN,                             
                      SAVE_FINAL_BLOCKS IN BOOLEAN,                             
                      NOFILEUPDATE      IN BOOLEAN,                             
                      DOCLEAR           IN BOOLEAN,                             
                      FLAGS_CLEAR       IN BINARY_INTEGER DEFAULT 0 )  IS       
  BEGIN                                                                         
     ICDSTART(97, CHKEVENTS=>TRUE);                                             
     KRBIBMRS(SAVE_ALL_BLOCKS, SAVE_FINAL_BLOCKS, NOFILEUPDATE,                 
              DOCLEAR, FLAGS_CLEAR);                                            
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBAB( DFNUMBER  IN  BINARY_INTEGER,                              
                     BLKNUMBER IN  BINARY_INTEGER );                            
  PRAGMA INTERFACE (C, KRBIBAB);                                                
                                                                                
  PROCEDURE BMRADDBLOCK ( DFNUMBER  IN  BINARY_INTEGER,                         
                          BLKNUMBER IN  BINARY_INTEGER,                         
                          RANGE     IN  BINARY_INTEGER DEFAULT 1 ) IS           
  BEGIN                                                                         
     ICDSTART(98);                                                              
     FOR I IN 1..RANGE LOOP                                                     
        KRBIBAB(DFNUMBER, BLKNUMBER + I - 1);                                   
     END LOOP;                                                                  
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBIS;                                                            
                                                                                
  PRAGMA INTERFACE (C, KRBIBIS);                                                
                                                                                
  PROCEDURE BMRINITIALSCAN IS                                                   
  BEGIN                                                                         
     ICDSTART(99);                                                              
     KRBIBIS;                                                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIBGF(FIRSTCALL IN BOOLEAN)                                        
           RETURN NUMBER;                                                       
  PRAGMA INTERFACE (C, KRBIBGF);                                                
                                                                                
  FUNCTION BMRGETFILE(FIRSTCALL IN BOOLEAN)                                     
           RETURN NUMBER IS                                                     
  DFNO     NUMBER;                                                              
  BEGIN                                                                         
     ICDSTART(100);                                                             
     DFNO := KRBIBGF(FIRSTCALL);                                                
     ICDFINISH;                                                                 
     RETURN DFNO;                                                               
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBMRC;                                                           
  PRAGMA INTERFACE (C, KRBIBMRC);                                               
                                                                                
                                                                                
  PROCEDURE BMRCANCEL IS                                                        
    BEGIN                                                                       
        ICDSTART(101);                                                          
        KRBIBMRC;                                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBID2RF( DBANO   IN  NUMBER,                                       
                      RFNO    OUT NUMBER,                                       
                      BLOCKNO OUT NUMBER,                                       
                      TSNUM   IN  BINARY_INTEGER );                             
  PRAGMA INTERFACE (C, KRBID2RF);                                               
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE DBA2RFNO( DBANO   IN  NUMBER,                                       
                      RFNO    OUT NUMBER,                                       
                      BLOCKNO OUT NUMBER ) IS                                   
  BEGIN                                                                         
       DBA2RFNO(DBANO   => DBANO,                                               
                RFNO    => RFNO,                                                
                BLOCKNO => BLOCKNO,                                             
                TSNUM   => NULL);                                               
  END;                                                                          
                                                                                
  PROCEDURE DBA2RFNO( DBANO   IN  NUMBER,                                       
                      RFNO    OUT NUMBER,                                       
                      BLOCKNO OUT NUMBER,                                       
                      TSNUM   IN  BINARY_INTEGER ) IS                           
  BEGIN                                                                         
        ICDSTART(102);                                                          
        KRBID2RF(DBANO, RFNO, BLOCKNO, TSNUM);                                  
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBUFC(RECID        IN  NUMBER,                                   
                     STAMP        IN  NUMBER);                                  
  PRAGMA INTERFACE (C, KRBIBUFC);                                               
                                                                                
  PROCEDURE BMRSCANDATAFILECOPY(RECID  IN NUMBER,                               
                                STAMP  IN NUMBER)                               
    IS                                                                          
        INPUT_RECID NUMBER NOT NULL := 0;                                       
        INPUT_STAMP NUMBER NOT NULL := 0;                                       
    BEGIN                                                                       
        ICDSTART(103);                                                          
        INPUT_RECID := RECID;                                                   
        INPUT_STAMP := STAMP;                                                   
        KRBIBUFC(RECID, STAMP);                                                 
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBDMR(ALNAME   IN VARCHAR2);                                     
  PRAGMA INTERFACE (C, KRBIBDMR);                                               
                                                                                
                                                                                
  PROCEDURE BMRDOMEDIARECOVERY(ALNAME IN VARCHAR2)                              
    IS                                                                          
    BEGIN                                                                       
        ICDSTART(104);                                                          
        KRBIBDMR(ALNAME);                                                       
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
  PROCEDURE KRBIIALBAC( FNAME            IN  VARCHAR2                           
                       ,THREAD           OUT  NUMBER                            
                       ,SEQUENCE         OUT  NUMBER                            
                       ,FIRST_CHANGE     OUT  NUMBER                            
                       ,ALL_LOGS         IN BOOLEAN DEFAULT TRUE );             
  PRAGMA INTERFACE (C, KRBIIALBAC);                                             
                                                                                
  PROCEDURE INCRARCHIVEDLOGBACKUPCOUNT(                                         
                                    FNAME            IN  VARCHAR2               
                                   ,THREAD           OUT  NUMBER                
                                   ,SEQUENCE         OUT  NUMBER                
                                   ,FIRST_CHANGE     OUT  NUMBER                
                                   ,ALL_LOGS         IN BOOLEAN DEFAULT TRUE )  
    IS                                                                          
    BEGIN                                                                       
        ICDSTART(105);                                                          
        KRBIIALBAC(FNAME, THREAD, SEQUENCE,                                     
                    FIRST_CHANGE,  ALL_LOGS);                                   
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIOMFN(TSNAME        IN  VARCHAR2,                                
                     OMFNAME       OUT VARCHAR2,                                
                     ISTEMP        IN  BOOLEAN);                                
  PRAGMA INTERFACE (C, KRBIOMFN);                                               
                                                                                
  PROCEDURE GETOMFFILENAME(TSNAME  IN  VARCHAR2,                                
                           OMFNAME OUT VARCHAR2) IS                             
    BEGIN                                                                       
        GETOMFFILENAME(TSNAME, OMFNAME, FALSE);                                 
    END;                                                                        
                                                                                
  PROCEDURE GETOMFFILENAME(TSNAME  IN  VARCHAR2,                                
                           OMFNAME OUT VARCHAR2,                                
                           ISTEMP  IN  BOOLEAN) IS                              
    BEGIN                                                                       
        ICDSTART(106);                                                          
        IF TSNAME IS NULL THEN                                                  
           KRBIRERR(19864, 'Tablespace name is NULL');                          
        END IF;                                                                 
        KRBIOMFN(TSNAME, OMFNAME, ISTEMP);                                      
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIGALN( DEST       IN   VARCHAR2                                   
                    ,FORMAT     IN   VARCHAR2      DEFAULT NULL                 
                    ,THREAD     IN   BINARY_INTEGER                             
                    ,SEQUENCE   IN   NUMBER                                     
                    ,RESETLOGS_ID IN NUMBER )                                   
  RETURN VARCHAR2;                                                              
  PRAGMA INTERFACE (C, KRBIGALN);                                               
                                                                                
                                                                                
  PROCEDURE INSPECTARCHIVEDLOGSEQ( LOG_DEST   IN   VARCHAR2                     
                                  ,FORMAT     IN   VARCHAR2   DEFAULT NULL      
                                  ,THREAD     IN   BINARY_INTEGER               
                                  ,SEQUENCE   IN   NUMBER                       
                                  ,FULL_NAME  OUT  VARCHAR2 ) IS                
  BEGIN                                                                         
      INSPECTARCHIVEDLOGSEQ(LOG_DEST, FORMAT, THREAD, SEQUENCE, FULL_NAME,      
                            NULL);                                              
  END;                                                                          
                                                                                
  PROCEDURE INSPECTARCHIVEDLOGSEQ( LOG_DEST   IN   VARCHAR2                     
                                  ,FORMAT     IN   VARCHAR2   DEFAULT NULL      
                                  ,THREAD     IN   BINARY_INTEGER               
                                  ,SEQUENCE   IN   NUMBER                       
                                  ,FULL_NAME  OUT  VARCHAR2                     
                                  ,RESETLOGS_ID IN NUMBER ) IS                  
    INPUT_DEST  VARCHAR2(513) NOT NULL := ' ';                                  
    FNAME       VARCHAR2(513);                                                  
    RECID       NUMBER;                                                         
    STAMP       NUMBER;                                                         
    BEGIN                                                                       
       ICDSTART(107);                                                           
       INPUT_DEST := LOG_DEST;                                                  
       FNAME := KRBIGALN(INPUT_DEST, FORMAT, THREAD, SEQUENCE, RESETLOGS_ID);   
       IF FNAME IS NOT NULL THEN                                                
          KRBIIF(IF_ARCHIVEDLOG, FNAME, FULL_NAME, RECID, STAMP);               
       END IF;                                                                  
       ICDFINISH;                                                               
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
  FUNCTION KRBICVRT(FNAME   IN VARCHAR2,                                        
                    FTYPE   IN BINARY_INTEGER,                                  
                    OSFTYPE IN BOOLEAN) RETURN VARCHAR2;                        
                                                                                
  PRAGMA INTERFACE (C, KRBICVRT);                                               
                                                                                
  FUNCTION CONVERTFILENAME(FNAME IN VARCHAR2,                                   
                           FTYPE IN BINARY_INTEGER) RETURN VARCHAR2 IS          
  BEGIN                                                                         
     RETURN CONVERTFILENAME(FNAME, FTYPE, FALSE);                               
  END;                                                                          
                                                                                
  FUNCTION CONVERTFILENAME(FNAME   IN VARCHAR2,                                 
                           FTYPE   IN BINARY_INTEGER,                           
                           OSFTYPE IN BOOLEAN) RETURN VARCHAR2 IS               
  IFNAME  VARCHAR2(1024) NOT NULL := ' ';                                       
  OFNAME  VARCHAR2(1024);                                                       
  BEGIN                                                                         
     ICDSTART(108);                                                             
     IFNAME := FNAME;                                                           
     OFNAME := KRBICVRT(IFNAME, FTYPE, OSFTYPE);                                
     ICDFINISH;                                                                 
     RETURN OFNAME;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBSF;                                                            
  PRAGMA INTERFACE (C, KRBIBSF);                                                
                                                                                
                                                                                
  PROCEDURE BACKUPSPFILE IS                                                     
    BEGIN                                                                       
        ICDSTART(109);                                                          
        KRBIBSF();                                                              
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRSFT( PFNAME IN VARCHAR2                                        
                     ,SFNAME IN VARCHAR2);                                      
  PRAGMA INTERFACE (C, KRBIRSFT);                                               
                                                                                
                                                                                
  PROCEDURE RESTORESPFILETO( PFNAME IN VARCHAR2 DEFAULT NULL                    
                            ,SFNAME IN VARCHAR2 DEFAULT NULL) IS                
    BEGIN                                                                       
        ICDSTART(110);                                                          
        KRBIRSFT(PFNAME, SFNAME);                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDAB ( NCOPIES OUT BINARY_INTEGER                                
                     ,LYEAR   IN BINARY_INTEGER                                 
                     ,LMONTH  IN BINARY_INTEGER                                 
                     ,LDAY    IN BINARY_INTEGER                                 
                     ,SEQ     IN BINARY_INTEGER                                 
                     ,FORMAT  IN VARCHAR2                                       
                     ,P1      IN BINARY_INTEGER                                 
                     ,P2      IN BINARY_INTEGER                                 
                     ,P3      IN BINARY_INTEGER                                 
                     ,P4      IN VARCHAR2                                       
                     ,NETALIAS IN VARCHAR2                                      
                     ,NOSPF    IN BOOLEAN);                                     
  PRAGMA INTERFACE (C, KRBIDAB);                                                
                                                                                
  PROCEDURE DOAUTOBACKUP (NCOPIES OUT BINARY_INTEGER                            
                          ,CFAUDATE IN DATE                                     
                          ,SEQ      IN BINARY_INTEGER                           
                          ,FORMAT   IN VARCHAR2) IS                             
  BEGIN                                                                         
     DOAUTOBACKUP(NCOPIES, CFAUDATE, SEQ, FORMAT, 0, 0, 0, NULL);               
  END;                                                                          
                                                                                
  PROCEDURE DOAUTOBACKUP(NCOPIES OUT BINARY_INTEGER                             
                         ,CFAUDATE   IN DATE           DEFAULT   NULL           
                         ,SEQ        IN BINARY_INTEGER DEFAULT NULL             
                         ,FORMAT     IN VARCHAR2       DEFAULT NULL             
                         ,P1         IN BINARY_INTEGER                          
                         ,P2         IN BINARY_INTEGER                          
                         ,P3         IN BINARY_INTEGER                          
                         ,P4         IN VARCHAR2) IS                            
     LYEAR  BINARY_INTEGER := -1;                                               
     LMONTH BINARY_INTEGER := -1;                                               
     LDAY   BINARY_INTEGER := -1;                                               
     LSEQ   BINARY_INTEGER := -1;                                               
  BEGIN                                                                         
     ICDSTART(111);                                                             
       IF (CFAUDATE IS NOT NULL) THEN                                           
         SELECT TO_CHAR(CFAUDATE, 'YYYY',                                       
                      'NLS_CALENDAR=Gregorian'),                                
              TO_CHAR(CFAUDATE, 'MM',                                           
                      'NLS_CALENDAR=Gregorian'),                                
              TO_CHAR(CFAUDATE, 'DD',                                           
                      'NLS_CALENDAR=Gregorian')                                 
              INTO LYEAR, LMONTH, LDAY                                          
         FROM DUAL;                                                             
       END IF;                                                                  
       IF (SEQ IS NOT NULL) THEN                                                
         LSEQ := SEQ;                                                           
       END IF;                                                                  
       KRBIDAB(NCOPIES, LYEAR, LMONTH, LDAY, LSEQ, FORMAT, P1, P2, P3, P4,      
               NULL, FALSE);                                                    
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
  PROCEDURE KRBIABF(FLAG IN BOOLEAN);                                           
  PRAGMA INTERFACE (C, KRBIABF);                                                
                                                                                
  PROCEDURE AUTOBACKUPFLAG(FLAG IN BOOLEAN) IS                                  
  BEGIN                                                                         
     ICDSTART(112);                                                             
       KRBIABF(FLAG);                                                           
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRCP( CNAME         IN   VARCHAR2                                
                    ,FNAME         IN   VARCHAR2                                
                    ,FULL_NAME     OUT  VARCHAR2                                
                    ,MAX_CORRUPT   IN   BINARY_INTEGER                          
                    ,CHECK_LOGICAL IN   BOOLEAN                                 
                    ,BLKSIZE       IN   BINARY_INTEGER                          
                    ,BLOCKS        IN   BINARY_INTEGER                          
                    ,FNO           IN   BINARY_INTEGER                          
                    ,SCNSTR        IN   VARCHAR2                                
                    ,RFNO          IN   BINARY_INTEGER                          
                    ,TSNAME        IN VARCHAR2);                                
                                                                                
  PRAGMA INTERFACE (C, KRBIRCP);                                                
                                                                                
  PROCEDURE RESDATAFILECOPY( CNAME         IN   VARCHAR2                        
                            ,FNAME         IN   VARCHAR2                        
                            ,FULL_NAME     OUT  VARCHAR2                        
                            ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0        
                            ,CHECK_LOGICAL IN   BOOLEAN                         
                            ,BLKSIZE       IN   BINARY_INTEGER                  
                            ,BLOCKS        IN   BINARY_INTEGER                  
                            ,FNO           IN   BINARY_INTEGER                  
                            ,SCNSTR        IN   VARCHAR2                        
                            ,RFNO          IN   BINARY_INTEGER) IS              
  BEGIN                                                                         
     RESDATAFILECOPY( CNAME               => CNAME                              
                     ,FNAME               => FNAME                              
                     ,FULL_NAME           => FULL_NAME                          
                     ,MAX_CORRUPT         => MAX_CORRUPT                        
                     ,CHECK_LOGICAL       => CHECK_LOGICAL                      
                     ,BLKSIZE             => BLKSIZE                            
                     ,BLOCKS              => BLOCKS                             
                     ,FNO                 => FNO                                
                     ,SCNSTR              => SCNSTR                             
                     ,RFNO                => RFNO                               
                     ,TSNAME              => TO_CHAR(NULL));                    
  END RESDATAFILECOPY;                                                          
                                                                                
  PROCEDURE RESDATAFILECOPY( CNAME         IN   VARCHAR2                        
                            ,FNAME         IN   VARCHAR2                        
                            ,FULL_NAME     OUT  VARCHAR2                        
                            ,MAX_CORRUPT   IN   BINARY_INTEGER DEFAULT 0        
                            ,CHECK_LOGICAL IN   BOOLEAN                         
                            ,BLKSIZE       IN   BINARY_INTEGER                  
                            ,BLOCKS        IN   BINARY_INTEGER                  
                            ,FNO           IN   BINARY_INTEGER                  
                            ,SCNSTR        IN   VARCHAR2                        
                            ,RFNO          IN   BINARY_INTEGER                  
                            ,TSNAME        IN   VARCHAR2) IS                    
  ICNAME  VARCHAR2(1024) NOT NULL := ' ';                                       
  IFNAME  VARCHAR2(1024) NOT NULL := ' ';                                       
  IBLKSIZE NUMBER NOT NULL := 0;                                                
  IBLOCKS NUMBER NOT NULL := 0;                                                 
  IFNO NUMBER NOT NULL := 0;                                                    
  ISCN  VARCHAR2(41) NOT NULL := ' ';                                           
  IRFNO NUMBER NOT NULL := 0;                                                   
    BEGIN                                                                       
        IFNAME := FNAME;                                                        
        ICNAME := CNAME;                                                        
        IBLKSIZE := BLKSIZE;                                                    
        IBLOCKS := BLOCKS;                                                      
        IFNO := FNO;                                                            
        ISCN := SCNSTR;                                                         
        IRFNO := RFNO;                                                          
        ICDSTART(113, CHKEVENTS=>TRUE);                                         
        SETMODULE('restore datafilecopy');                                      
        IF ICNAME IS NULL THEN                                                  
           KRBIRERR(19864, 'Input filename is NULL');                           
        END IF;                                                                 
        IF IFNAME IS NULL THEN                                                  
           KRBIRERR(19864, 'Output filename is NULL');                          
        END IF;                                                                 
        IF ISCN IS NULL THEN                                                    
           KRBIRERR(19864, 'Checkpoint scn is NULL');                           
        END IF;                                                                 
        KRBIRCP(ICNAME, IFNAME, FULL_NAME, MAX_CORRUPT, CHECK_LOGICAL,          
                IBLKSIZE, IBLOCKS, IFNO, ISCN, RFNO, TSNAME);                   
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRAGF;                                                           
  PRAGMA INTERFACE (C, KRBIRAGF);                                               
                                                                                
                                                                                
  PROCEDURE REFRESHAGEDFILES IS                                                 
    BEGIN                                                                       
        ICDSTART(114);                                                          
        KRBIRAGF;                                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIFBS( SCNBASED      IN BINARY_INTEGER                            
                    ,TOBEFORE      IN BINARY_INTEGER                            
                    ,FLASHBACKSCN  IN NUMBER                                    
                    ,FLASHBACKTIME IN DATE                                      
                    ,FLASHBACKINC  IN NUMBER );                                 
  PRAGMA INTERFACE (C, KRBIFBS);                                                
                                                                                
  PROCEDURE FLASHBACKSTART( FLASHBACKSCN  IN NUMBER                             
                           ,FLASHBACKTIME IN DATE                               
                           ,SCNBASED      IN BINARY_INTEGER                     
                           ,TOBEFORE      IN BINARY_INTEGER) IS                 
  BEGIN                                                                         
     FLASHBACKSTART(FLASHBACKSCN, FLASHBACKTIME, SCNBASED, TOBEFORE, NULL,      
                    NULL);                                                      
  END;                                                                          
                                                                                
  PROCEDURE FLASHBACKSTART( FLASHBACKSCN  IN NUMBER                             
                           ,FLASHBACKTIME IN DATE                               
                           ,SCNBASED      IN BINARY_INTEGER                     
                           ,TOBEFORE      IN BINARY_INTEGER                     
                           ,RESETSCN      IN NUMBER                             
                           ,RESETTIME     IN DATE ) IS                          
       FLASHBACKINC  NUMBER;                                                    
    BEGIN                                                                       
       ICDSTART(115, CHKEVENTS=>TRUE);                                          
       IF (RESETSCN IS NULL OR RESETTIME IS NULL) THEN                          
          FLASHBACKINC := 0;                                                    
       ELSE                                                                     
          SELECT INCARNATION#                                                   
            INTO FLASHBACKINC                                                   
            FROM V$DATABASE_INCARNATION                                         
           WHERE RESETLOGS_CHANGE# = RESETSCN                                   
             AND RESETLOGS_TIME = RESETTIME;                                    
       END IF;                                                                  
       KRBIFBS(SCNBASED, TOBEFORE, FLASHBACKSCN, FLASHBACKTIME, FLASHBACKINC);  
       ICDFINISH;                                                               
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIFBAF( FILENO IN  BINARY_INTEGER );                              
  PRAGMA INTERFACE (C, KRBIFBAF);                                               
                                                                                
  PROCEDURE FLASHBACKADDFILE( FILENO IN BINARY_INTEGER ) IS                     
    BEGIN                                                                       
       ICDSTART(116);                                                           
       KRBIFBAF(FILENO);                                                        
       ICDFINISH;                                                               
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIFBF(ALNAME IN VARCHAR2);                                        
  PRAGMA INTERFACE (C, KRBIFBF);                                                
                                                                                
                                                                                
  PROCEDURE FLASHBACKFILES(ALNAME IN VARCHAR2)                                  
    IS                                                                          
    BEGIN                                                                       
        ICDSTART(117);                                                          
        KRBIFBF(ALNAME);                                                        
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
          ICDFINISH;                                                            
          RAISE;                                                                
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIFBC;                                                            
  PRAGMA INTERFACE (C, KRBIFBC);                                                
                                                                                
                                                                                
  PROCEDURE FLASHBACKCANCEL IS                                                  
    BEGIN                                                                       
        ICDSTART(118);                                                          
        KRBIFBC;                                                                
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRSP( HANDLE   IN VARCHAR2                                       
                    ,TAG      IN VARCHAR2                                       
                    ,FROMDISK IN BOOLEAN                                        
                    ,RECID    IN NUMBER                                         
                    ,STAMP    IN NUMBER );                                      
  PRAGMA INTERFACE (C, KRBIRSP);                                                
                                                                                
                                                                                
  PROCEDURE RESTORESETPIECE( HANDLE   IN   VARCHAR2                             
                            ,TAG      IN   VARCHAR2                             
                            ,FROMDISK IN   BOOLEAN                              
                            ,RECID    IN   NUMBER                               
                            ,STAMP    IN   NUMBER ) IS                          
        INPUT_HANDLE  VARCHAR2(513) NOT NULL := ' ';                            
  BEGIN                                                                         
     ICDSTART(119);                                                             
                                                                                
     INPUT_HANDLE := HANDLE;                                                    
     KRBIRSP(HANDLE, TAG, FROMDISK, RECID, STAMP);                              
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
  PROCEDURE RESTOREBACKUPPIECE( HANDLE   IN   VARCHAR2                          
                               ,DONE     OUT  BOOLEAN                           
                               ,PARAMS   IN   VARCHAR2  DEFAULT NULL            
                               ,FROMDISK IN   BOOLEAN   DEFAULT FALSE ) IS      
    FAILOVER     BOOLEAN;                                                       
    OUTHANDLE    VARCHAR2(513);                                                 
    OUTTAG       VARCHAR2(256);                                                 
    INPUT_HANDLE  VARCHAR2(513) NOT NULL := ' ';                                
    BEGIN                                                                       
        ICDSTART(120);                                                          
                                                                                
        INPUT_HANDLE := HANDLE;                                                 
        KRBIRSP(HANDLE, NULL, FROMDISK, 0, 0);                                  
        KRBIRBP(DONE, PARAMS, OUTHANDLE, OUTTAG, FAILOVER);                     
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIFFR( FIRSTCALL  IN  BOOLEAN                                      
                   ,PROXY      IN  BOOLEAN                                      
                   ,FTYPE      OUT BINARY_INTEGER                               
                   ,FNO        OUT BINARY_INTEGER                               
                   ,THREAD     OUT BINARY_INTEGER                               
                   ,SEQUENCE   OUT NUMBER                                       
                   ,RESETSCN   OUT NUMBER                                       
                   ,RESETSTAMP OUT NUMBER                                       
                   ,FNAME      OUT VARCHAR2 ) RETURN BINARY_INTEGER;            
  PRAGMA INTERFACE (C, KRBIFFR);                                                
                                                                                
                                                                                
  FUNCTION FETCHFILERESTORED( FIRSTCALL  IN  BOOLEAN                            
                             ,PROXY      IN  BOOLEAN                            
                             ,FTYPE      OUT BINARY_INTEGER                     
                             ,FNO        OUT BINARY_INTEGER                     
                             ,THREAD     OUT BINARY_INTEGER                     
                             ,SEQUENCE   OUT NUMBER                             
                             ,RESETSCN   OUT NUMBER                             
                             ,RESETSTAMP OUT NUMBER ) RETURN BINARY_INTEGER IS  
     FNAME VARCHAR2(1024);                                                      
  BEGIN                                                                         
     RETURN FETCHFILERESTORED(FIRSTCALL    => FIRSTCALL,                        
                              PROXY        => PROXY,                            
                              FTYPE        => FTYPE,                            
                              FNO          => FNO,                              
                              THREAD       => THREAD,                           
                              SEQUENCE     => SEQUENCE,                         
                              RESETSCN     => RESETSCN,                         
                              RESETSTAMP   => RESETSTAMP,                       
                              FNAME        => FNAME);                           
                                                                                
  END;                                                                          
                                                                                
                                                                                
  FUNCTION FETCHFILERESTORED( FIRSTCALL  IN  BOOLEAN                            
                             ,PROXY      IN  BOOLEAN                            
                             ,FTYPE      OUT BINARY_INTEGER                     
                             ,FNO        OUT BINARY_INTEGER                     
                             ,THREAD     OUT BINARY_INTEGER                     
                             ,SEQUENCE   OUT NUMBER                             
                             ,RESETSCN   OUT NUMBER                             
                             ,RESETSTAMP OUT NUMBER                             
                             ,FNAME      OUT VARCHAR2)                          
  RETURN BINARY_INTEGER IS                                                      
     FILERESTORED BINARY_INTEGER;                                               
  BEGIN                                                                         
     ICDSTART(121);                                                             
     FILERESTORED := KRBIFFR(FIRSTCALL, PROXY, FTYPE, FNO, THREAD,              
                             SEQUENCE, RESETSCN, RESETSTAMP, FNAME);            
     ICDFINISH;                                                                 
     RETURN FILERESTORED;                                                       
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIGTSN(FNAME      IN VARCHAR2                                      
                   ,FNO        IN BINARY_INTEGER) RETURN VARCHAR2;              
  PRAGMA INTERFACE (C, KRBIGTSN);                                               
                                                                                
  FUNCTION GETTSNAMEFROMDATAFILECOPY(FNAME      IN VARCHAR2                     
                                    ,FNO        IN NUMBER)                      
                                             RETURN VARCHAR2 IS                 
  IFNAME  VARCHAR2(512) NOT NULL := ' ';                                        
  OFNAME  VARCHAR2(30);                                                         
  IFNO    BINARY_INTEGER NOT NULL := 0;                                         
  BEGIN                                                                         
     ICDSTART(122);                                                             
     IFNAME := FNAME;                                                           
     IFNO := FNO;                                                               
     OFNAME := KRBIGTSN(FNAME, IFNO);                                           
     ICDFINISH;                                                                 
     RETURN OFNAME;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISF(PATTERN IN OUT VARCHAR2                                      
                  ,NS      IN OUT VARCHAR2                                      
                  ,CCF     IN     BOOLEAN   DEFAULT FALSE                       
                  ,OMF     IN     BOOLEAN   DEFAULT FALSE                       
                  ,FTYPE   IN     VARCHAR2  DEFAULT NULL);                      
  PRAGMA INTERFACE (C, KRBISF);                                                 
                                                                                
                                                                                
  PROCEDURE SEARCHFILES(PATTERN IN OUT  VARCHAR2                                
                       ,NS      IN OUT  VARCHAR2                                
                       ,CCF     IN      BOOLEAN        DEFAULT FALSE            
                       ,OMF     IN      BOOLEAN        DEFAULT FALSE            
                       ,FTYPE   IN      VARCHAR2       DEFAULT NULL) IS         
  BEGIN                                                                         
     ICDSTART(123, CHKEVENTS=>TRUE);                                            
     KRBISF(PATTERN, NS, CCF, OMF, FTYPE);                                      
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPSFT(CATALOG  IN BOOLEAN,                                       
                     IMPLICIT IN BINARY_INTEGER,                                
                     FORFTYPE IN BINARY_INTEGER);                               
  PRAGMA INTERFACE (C, KRBIPSFT);                                               
                                                                                
                                                                                
  PROCEDURE PROCESSSEARCHFILETABLE(CATALOG  IN BOOLEAN,                         
                                   IMPLICIT IN BINARY_INTEGER) IS               
  BEGIN                                                                         
     PROCESSSEARCHFILETABLE(CATALOG, IMPLICIT, 2**16-1);                        
  END;                                                                          
                                                                                
  PROCEDURE PROCESSSEARCHFILETABLE(CATALOG  IN BOOLEAN,                         
                                   IMPLICIT IN BINARY_INTEGER,                  
                                   FORFTYPE IN BINARY_INTEGER) IS               
  BEGIN                                                                         
     ICDSTART(124);                                                             
     KRBIPSFT(CATALOG, IMPLICIT, FORFTYPE);                                     
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIFSFT(                                                            
                     MUSTSPFILE IN  BOOLEAN                                     
                    ,UNTIL      IN  NUMBER                                      
                    ,FNAME      OUT VARCHAR2                                    
                    ,YEAR       OUT BINARY_INTEGER                              
                    ,MONTH      OUT BINARY_INTEGER                              
                    ,DAY        OUT BINARY_INTEGER                              
                    ,SEQUENCE   OUT BINARY_INTEGER                              
                    ,ATS        OUT NUMBER)                                     
    RETURN BOOLEAN;                                                             
  PRAGMA INTERFACE (C, KRBIFSFT);                                               
                                                                                
  FUNCTION FINDAUTSEARCHFILETABLE( MUSTSPFILE IN  BOOLEAN                       
                                  ,UNTIL      IN  NUMBER                        
                                  ,FNAME      OUT VARCHAR2                      
                                  ,YEAR       OUT BINARY_INTEGER                
                                  ,MONTH      OUT BINARY_INTEGER                
                                  ,DAY        OUT BINARY_INTEGER                
                                  ,SEQUENCE   OUT BINARY_INTEGER                
                                  ,ATS        OUT NUMBER)                       
  RETURN BOOLEAN IS                                                             
     FOUND BOOLEAN;                                                             
  BEGIN                                                                         
     ICDSTART(125);                                                             
     FOUND := KRBIFSFT(MUSTSPFILE, UNTIL, FNAME, YEAR, MONTH, DAY,              
                       SEQUENCE, ATS);                                          
     ICDFINISH;                                                                 
     RETURN FOUND;                                                              
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
   PROCEDURE KRBISWITCH(FILELIST IN VARCHAR2);                                  
   PRAGMA INTERFACE (C, KRBISWITCH);                                            
                                                                                
   PROCEDURE BCTSWITCH(FILELIST IN VARCHAR2) IS                                 
     BEGIN                                                                      
        ICDSTART(126);                                                          
        SETMODULE('bctSwitch');                                                 
        KRBISWITCH(FILELIST);                                                   
        ICDFINISH;                                                              
     EXCEPTION                                                                  
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
     END;                                                                       
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
   PROCEDURE KRBICTSET(PARMNO  IN BINARY_INTEGER,                               
                       NUMVAL  IN NUMBER,                                       
                       CHARVAL IN VARCHAR2);                                    
   PRAGMA INTERFACE (C, KRBICTSET);                                             
                                                                                
   PROCEDURE BCTSET(PARMNO  IN BINARY_INTEGER,                                  
                    NUMVAL  IN NUMBER,                                          
                    CHARVAL IN VARCHAR2) IS                                     
     BEGIN                                                                      
        ICDSTART(127);                                                          
        SETMODULE('bctSet');                                                    
        KRBICTSET(PARMNO, NUMVAL, CHARVAL);                                     
        ICDFINISH;                                                              
     EXCEPTION                                                                  
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
     END;                                                                       
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRDB(DBINC_KEY IN NUMBER);                                       
  PRAGMA INTERFACE (C, KRBIRDB);                                                
                                                                                
  PROCEDURE RESETDATABASE(DBINC_KEY IN   NUMBER) IS                             
     IDBINC_KEY NUMBER NOT NULL := 0;                                           
    BEGIN                                                                       
        ICDSTART(128);                                                          
        IDBINC_KEY := DBINC_KEY;                                                
        KRBIRDB(IDBINC_KEY);                                                    
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICRSR( LEVEL         IN  BINARY_INTEGER                          
                     ,PARENT_ID     IN  NUMBER                                  
                     ,PARENT_STAMP  IN  NUMBER                                  
                     ,STATUS        IN  BINARY_INTEGER                          
                     ,COMMAND_ID    IN  VARCHAR2                                
                     ,OPERATION     IN  VARCHAR2                                
                     ,ROW_ID        OUT NUMBER                                  
                     ,ROW_STAMP     OUT NUMBER                                  
                     ,FLAGS         IN  BINARY_INTEGER);                        
   PRAGMA INTERFACE (C, KRBICRSR);                                              
                                                                                
  PROCEDURE CREATERMANSTATUSROW( LEVEL         IN  BINARY_INTEGER               
                                ,PARENT_ID     IN  NUMBER                       
                                ,PARENT_STAMP  IN  NUMBER                       
                                ,STATUS        IN  BINARY_INTEGER               
                                ,COMMAND_ID    IN  VARCHAR2                     
                                ,OPERATION     IN  VARCHAR2                     
                                ,ROW_ID        OUT NUMBER                       
                                ,ROW_STAMP     OUT NUMBER                       
                                ,FLAGS         IN  BINARY_INTEGER) IS           
     INPUT_LEVEL        BINARY_INTEGER  NOT NULL := 0;                          
     INPUT_PARENT_ID    NUMBER          NOT NULL := 0;                          
     INPUT_PARENT_STAMP NUMBER          NOT NULL := 0;                          
     INPUT_STATUS       BINARY_INTEGER  NOT NULL := 0;                          
     INPUT_COMMAND_ID   VARCHAR2(512)   NOT NULL := ' ';                        
     INPUT_OPERATION    VARCHAR2(512)   NOT NULL := ' ';                        
     INPUT_FLAGS        BINARY_INTEGER  NOT NULL := 0;                          
  BEGIN                                                                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
     INPUT_LEVEL        := LEVEL;                                               
     INPUT_PARENT_ID    := PARENT_ID;                                           
     INPUT_PARENT_STAMP := PARENT_STAMP;                                        
     INPUT_STATUS       := STATUS;                                              
     INPUT_COMMAND_ID   := COMMAND_ID;                                          
     INPUT_OPERATION    := OPERATION;                                           
     INPUT_FLAGS        := FLAGS;                                               
                                                                                
     KRBICRSR(INPUT_LEVEL, INPUT_PARENT_ID, INPUT_PARENT_STAMP, INPUT_STATUS,   
              INPUT_COMMAND_ID, INPUT_OPERATION, ROW_ID, ROW_STAMP, INPUT_FLAGS)
;                                                                               
                                                                                
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     RAISE;                                                                     
  END;                                                                          
                                                                                
  PROCEDURE CREATERMANSTATUSROW( LEVEL         IN  BINARY_INTEGER               
                                ,PARENT_ID     IN  NUMBER                       
                                ,PARENT_STAMP  IN  NUMBER                       
                                ,STATUS        IN  BINARY_INTEGER               
                                ,COMMAND_ID    IN  VARCHAR2                     
                                ,OPERATION     IN  VARCHAR2                     
                                ,ROW_ID        OUT NUMBER                       
                                ,ROW_STAMP     OUT NUMBER ) IS                  
  BEGIN                                                                         
           CREATERMANSTATUSROW( LEVEL ,PARENT_ID ,PARENT_STAMP ,STATUS,         
                                COMMAND_ID ,OPERATION, ROW_ID, ROW_STAMP, 0);   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIURSR( ROW_ID     IN NUMBER                                      
                     ,ROW_STAMP  IN NUMBER                                      
                     ,STATUS     IN BINARY_INTEGER);                            
   PRAGMA INTERFACE (C, KRBIURSR);                                              
                                                                                
  PROCEDURE UPDATERMANSTATUSROW( ROW_ID     IN NUMBER                           
                                ,ROW_STAMP  IN NUMBER                           
                                ,STATUS     IN BINARY_INTEGER) IS               
     INPUT_ROW_ID     NUMBER          NOT NULL := 0;                            
     INPUT_ROW_STAMP  NUMBER          NOT NULL := 0;                            
     INPUT_STATUS     BINARY_INTEGER  NOT NULL := 0;                            
  BEGIN                                                                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
     INPUT_ROW_ID     := ROW_ID;                                                
     INPUT_ROW_STAMP  := ROW_STAMP;                                             
     INPUT_STATUS     := STATUS;                                                
                                                                                
     KRBIURSR(INPUT_ROW_ID, INPUT_ROW_STAMP, INPUT_STATUS);                     
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIMRSR( ROW_ID    IN NUMBER                                       
                     ,ROW_STAMP IN NUMBER                                       
                     ,MBYTES    IN NUMBER                                       
                     ,STATUS    IN BINARY_INTEGER                               
                     ,IBYTES    IN VARCHAR2                                     
                     ,OBYTES    IN VARCHAR2                                     
                     ,ODEVTYPE  IN VARCHAR2);                                   
   PRAGMA INTERFACE (C, KRBIMRSR);                                              
                                                                                
  PROCEDURE COMMITRMANSTATUSROW( ROW_ID    IN NUMBER                            
                                ,ROW_STAMP IN NUMBER                            
                                ,MBYTES    IN NUMBER                            
                                ,STATUS    IN BINARY_INTEGER                    
                                ,IBYTES    IN NUMBER                            
                                ,OBYTES    IN NUMBER                            
                                ,ODEVTYPE  IN VARCHAR2) IS                      
     INPUT_ROW_ID     NUMBER          NOT NULL := 0;                            
     INPUT_ROW_STAMP  NUMBER          NOT NULL := 0;                            
     INPUT_STATUS     BINARY_INTEGER  NOT NULL := 0;                            
     INPUT_MBYTES     NUMBER          NOT NULL := 0;                            
     INPUT_IBYTES     NUMBER          NOT NULL := 0;                            
     INPUT_OBYTES     NUMBER          NOT NULL := 0;                            
  BEGIN                                                                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
     INPUT_ROW_ID    := ROW_ID;                                                 
     INPUT_ROW_STAMP := ROW_STAMP;                                              
     INPUT_MBYTES    := MBYTES;                                                 
     INPUT_STATUS    := STATUS;                                                 
     INPUT_IBYTES    := IBYTES;                                                 
     INPUT_OBYTES    := OBYTES;                                                 
                                                                                
                                                                                
     KRBIMRSR(INPUT_ROW_ID, INPUT_ROW_STAMP, INPUT_MBYTES, INPUT_STATUS,        
              TO_CHAR(INPUT_IBYTES), TO_CHAR(INPUT_OBYTES), ODEVTYPE);          
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
  PROCEDURE COMMITRMANSTATUSROW( ROW_ID    IN NUMBER                            
                                ,ROW_STAMP IN NUMBER                            
                                ,MBYTES    IN NUMBER                            
                                ,STATUS    IN BINARY_INTEGER) IS                
  BEGIN                                                                         
      COMMITRMANSTATUSROW( ROW_ID                                               
                          ,ROW_STAMP                                            
                          ,MBYTES                                               
                          ,STATUS,                                              
                          0, 0, NULL );                                         
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICROR( L0ROW_ID    IN NUMBER                                     
                     ,L0ROW_STAMP IN NUMBER                                     
                     ,ROW_ID      IN NUMBER                                     
                     ,ROW_STAMP   IN NUMBER                                     
                     ,TXT         IN VARCHAR2                                   
                     ,SAMELINE    IN BINARY_INTEGER);                           
   PRAGMA INTERFACE (C, KRBICROR);                                              
                                                                                
  PROCEDURE CREATERMANOUTPUTROW( L0ROW_ID    IN NUMBER                          
                                ,L0ROW_STAMP IN NUMBER                          
                                ,ROW_ID      IN NUMBER                          
                                ,ROW_STAMP   IN NUMBER                          
                                ,TXT         IN VARCHAR2                        
                                ,SAMELINE    IN BINARY_INTEGER) IS              
     INPUT_ROW_ID      NUMBER          NOT NULL := 0;                           
     INPUT_ROW_STAMP   NUMBER          NOT NULL := 0;                           
     INPUT_L0ROW_ID    NUMBER          NOT NULL := 0;                           
     INPUT_L0ROW_STAMP NUMBER          NOT NULL := 0;                           
     INPUT_TXT         VARCHAR2(512)   NOT NULL := ' ';                         
     INPUT_SAMELINE    BINARY_INTEGER  NOT NULL := 0;                           
  BEGIN                                                                         
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
     INPUT_ROW_ID      := ROW_ID;                                               
     INPUT_ROW_STAMP   := ROW_STAMP;                                            
     INPUT_L0ROW_ID    := L0ROW_ID;                                             
     INPUT_L0ROW_STAMP := L0ROW_STAMP;                                          
     INPUT_TXT         := TXT;                                                  
     INPUT_SAMELINE    := SAMELINE;                                             
     IF INPUT_TXT IS NULL THEN                                                  
        KRBIRERR(19864, 'Input text is NULL');                                  
     END IF;                                                                    
     KRBICROR(INPUT_L0ROW_ID, INPUT_L0ROW_STAMP,                                
              INPUT_ROW_ID, INPUT_ROW_STAMP, INPUT_TXT, INPUT_SAMELINE);        
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     RAISE;                                                                     
  END;                                                                          
                                                                                
  PROCEDURE CREATERMANOUTPUTROW( L0ROW_ID    IN NUMBER                          
                                ,L0ROW_STAMP IN NUMBER                          
                                ,ROW_ID      IN NUMBER                          
                                ,ROW_STAMP   IN NUMBER                          
                                ,TXT         IN VARCHAR2) IS                    
  BEGIN                                                                         
     CREATERMANOUTPUTROW( L0ROW_ID, L0ROW_STAMP ,ROW_ID, ROW_STAMP ,TXT, 0);    
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISRID( RSID    IN NUMBER                                         
                     ,RSTS    IN NUMBER);                                       
   PRAGMA INTERFACE (C, KRBISRID);                                              
                                                                                
  PROCEDURE SETRMANSTATUSROWID( RSID    IN NUMBER                               
                               ,RSTS    IN NUMBER) IS                           
     INPUT_RSID   NUMBER    NOT NULL := 0;                                      
     INPUT_RSTS   NUMBER    NOT NULL := 0;                                      
     CHKEVENTS    BOOLEAN            := FALSE;                                  
  BEGIN                                                                         
     IF RSID IS NOT NULL AND RSID <> 0 THEN                                     
        CHKEVENTS := TRUE;                                                      
     END IF;                                                                    
     ICDSTART(129, CHKEVENTS);                                                  
                                                                                
     INPUT_RSID  := RSID;                                                       
     INPUT_RSTS  := RSTS;                                                       
     KRBISRID(INPUT_RSID, INPUT_RSTS);                                          
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRDHD(FNAME    IN VARCHAR2,                                      
                     DBNAME   OUT VARCHAR2,                                     
                     DBID     OUT NUMBER,                                       
                     TSNAME   OUT VARCHAR2,                                     
                     FNO      OUT BINARY_INTEGER,                               
                     NBLOCKS  OUT NUMBER,                                       
                     BLKSIZE  OUT BINARY_INTEGER,                               
                     PLID     OUT BINARY_INTEGER,                               
                     SAMEEN   IN  BINARY_INTEGER);                              
  PRAGMA INTERFACE (C, KRBIRDHD);                                               
                                                                                
  PROCEDURE READFILEHEADER(FNAME    IN VARCHAR2,                                
                           DBNAME   OUT VARCHAR2,                               
                           DBID     OUT NUMBER,                                 
                           TSNAME   OUT VARCHAR2,                               
                           FNO      OUT BINARY_INTEGER,                         
                           NBLOCKS  OUT NUMBER,                                 
                           BLKSIZE  OUT BINARY_INTEGER,                         
                           PLID     OUT BINARY_INTEGER,                         
                           SAMEEN   IN  BINARY_INTEGER) IS                      
     IFNAME    VARCHAR2(513) NOT NULL := ' ';                                   
     ISAMEEN   BINARY_INTEGER NOT NULL := 0;                                    
  BEGIN                                                                         
     ICDSTART(130);                                                             
                                                                                
     IFNAME := FNAME;                                                           
     ISAMEEN := SAMEEN;                                                         
     KRBIRDHD(FNAME, DBNAME, DBID, TSNAME, FNO, NBLOCKS, BLKSIZE, PLID,         
              SAMEEN);                                                          
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIDEFT(DEFTAG OUT VARCHAR2);                                      
  PRAGMA INTERFACE (C, KRBIDEFT);                                               
                                                                                
                                                                                
  PROCEDURE GETDEFAULTTAG(DEFTAG OUT VARCHAR2) IS                               
  BEGIN                                                                         
     ICDSTART(131);                                                             
     KRBIDEFT(DEFTAG);                                                          
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBICF(FNAME       IN VARCHAR2,                                     
                   MAX_CORRUPT IN BINARY_INTEGER);                              
                                                                                
  PRAGMA INTERFACE (C, KRBICF);                                                 
                                                                                
  PROCEDURE CONVERTDATAFILECOPY(FNAME       IN VARCHAR2,                        
                                MAX_CORRUPT IN BINARY_INTEGER DEFAULT 0) IS     
     IFNAME    VARCHAR2(513) NOT NULL := ' ';                                   
  BEGIN                                                                         
     ICDSTART(132);                                                             
                                                                                
     IFNAME := FNAME;                                                           
     KRBICF(FNAME, MAX_CORRUPT);                                                
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIININS;                                                          
                                                                                
  PRAGMA INTERFACE (C, KRBIININS);                                              
                                                                                
  PROCEDURE INITNAMESPACE IS                                                    
  BEGIN                                                                         
     ICDSTART(133);                                                             
     KRBIININS;                                                                 
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIMAUX( ORASID      IN     VARCHAR2                               
                     ,CLEANUP     IN     BINARY_INTEGER);                       
                                                                                
  PRAGMA INTERFACE (C, KRBIMAUX);                                               
                                                                                
  PROCEDURE MANAGEAUXINSTANCE( ORASID      IN     VARCHAR2                      
                              ,CLEANUP     IN     BINARY_INTEGER)               
  IS                                                                            
  IORASID  VARCHAR2(31) NOT NULL := ' ';                                        
  ICLEANUP BINARY_INTEGER NOT NULL := 0;                                        
  BEGIN                                                                         
     ICDSTART(134, CHKEVENTS=>TRUE);                                            
                                                                                
     IORASID := ORASID;                                                         
     ICLEANUP := CLEANUP;                                                       
     KRBIMAUX(ORASID, CLEANUP);                                                 
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIGCS( CNCTSTR      OUT    VARCHAR2                               
                    ,ORASID       IN     VARCHAR2                               
                    ,ESCAPED      IN     BOOLEAN);                              
                                                                                
  PRAGMA INTERFACE (C, KRBIGCS);                                                
                                                                                
  PROCEDURE GETCNCTSTR( CNCTSTR      OUT    VARCHAR2                            
                       ,ORASID       IN     VARCHAR2                            
                       ,ESCAPED      IN     BOOLEAN)                            
  IS                                                                            
  IORASID  VARCHAR2(31) NOT NULL := ' ';                                        
  IESCAPED BOOLEAN NOT NULL := FALSE;                                           
  BEGIN                                                                         
     ICDSTART(135);                                                             
                                                                                
     IORASID := ORASID;                                                         
     IESCAPED := ESCAPED;                                                       
     KRBIGCS(CNCTSTR, ORASID, ESCAPED);                                         
     IF LENGTH(CNCTSTR) = 0 THEN                                                
        CNCTSTR := NULL;                                                        
     END IF;                                                                    
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIVALS;                                                           
  PRAGMA INTERFACE (C, KRBIVALS);                                               
                                                                                
                                                                                
  PROCEDURE VALIDATIONSTART IS                                                  
    BEGIN                                                                       
        ICDSTART(146, CHKEVENTS=>TRUE);                                         
        KRBIVALS;                                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIVALA( RECID      IN  NUMBER                                     
                     ,STAMP      IN  NUMBER                                     
                     ,HANDLE     IN  VARCHAR2                                   
                     ,SET_STAMP  IN  NUMBER                                     
                     ,SET_COUNT  IN  NUMBER                                     
                     ,PIECENO    IN  NUMBER                                     
                     ,PARAMS     IN  VARCHAR2 DEFAULT NULL                      
                     ,HDL_ISDISK IN  BINARY_INTEGER);                           
  PRAGMA INTERFACE (C, KRBIVALA);                                               
                                                                                
  PROCEDURE VALIDATIONADDPIECE( RECID      IN  NUMBER                           
                               ,STAMP      IN  NUMBER                           
                               ,HANDLE     IN  VARCHAR2                         
                               ,SET_STAMP  IN  NUMBER                           
                               ,SET_COUNT  IN  NUMBER                           
                               ,PIECENO    IN  NUMBER                           
                               ,PARAMS     IN  VARCHAR2 DEFAULT NULL            
                               ,HDL_ISDISK IN  BINARY_INTEGER) IS               
    BEGIN                                                                       
        ICDSTART(147);                                                          
        KRBIVALA(RECID, STAMP, HANDLE, SET_STAMP, SET_COUNT, PIECENO,           
                 PARAMS, HDL_ISDISK);                                           
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIVALV(FLAGS IN BINARY_INTEGER);                                  
  PRAGMA INTERFACE (C, KRBIVALV);                                               
                                                                                
                                                                                
  PROCEDURE VALIDATIONVALIDATE IS                                               
    BEGIN                                                                       
        VALIDATIONVALIDATE(0);                                                  
    END;                                                                        
                                                                                
  PROCEDURE VALIDATIONVALIDATE(FLAGS IN BINARY_INTEGER) IS                      
        FLAGS_IN BINARY_INTEGER NOT NULL := 0;                                  
    BEGIN                                                                       
        ICDSTART(148);                                                          
        FLAGS_IN := FLAGS;                                                      
        KRBIVALV(FLAGS_IN);                                                     
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIVALN( HANDLE     OUT VARCHAR2                                   
                     ,RECID      OUT NUMBER                                     
                     ,SET_STAMP  OUT NUMBER                                     
                     ,SET_COUNT  OUT NUMBER                                     
                     ,PIECENO    OUT NUMBER                                     
                     ,MSCA       OUT BINARY_INTEGER                             
                     ,M1         OUT VARCHAR2                                   
                     ,M2         OUT VARCHAR2                                   
                     ,M3         OUT VARCHAR2                                   
                     ,M4         OUT VARCHAR2                                   
                     ,M5         OUT VARCHAR2                                   
                     ,M6         OUT VARCHAR2                                   
                     ,M7         OUT VARCHAR2                                   
                     ,M8         OUT VARCHAR2                                   
                     ,M9         OUT VARCHAR2                                   
                     ,M10        OUT VARCHAR2                                   
                     ,M11        OUT VARCHAR2                                   
                     ,M12        OUT VARCHAR2                                   
                     ,M13        OUT VARCHAR2                                   
                     ,M14        OUT VARCHAR2                                   
                     ,M15        OUT VARCHAR2                                   
                     ,M16        OUT VARCHAR2                                   
                     ,M17        OUT VARCHAR2                                   
                     ,M18        OUT VARCHAR2                                   
                     ,M19        OUT VARCHAR2                                   
                     ,M20        OUT VARCHAR2                                   
                     ,ATTRIBUTES OUT BINARY_INTEGER                             
                     );                                                         
  PRAGMA INTERFACE (C, KRBIVALN);                                               
                                                                                
  PROCEDURE VALIDATIONNEXTRESULT( HANDLE     OUT VARCHAR2                       
                                 ,RECID      OUT NUMBER                         
                                 ,SET_STAMP  OUT NUMBER                         
                                 ,SET_COUNT  OUT NUMBER                         
                                 ,PIECENO    OUT NUMBER                         
                                 ,MSCA       OUT BINARY_INTEGER                 
                                 ,M1         OUT VARCHAR2                       
                                 ,M2         OUT VARCHAR2                       
                                 ,M3         OUT VARCHAR2                       
                                 ,M4         OUT VARCHAR2                       
                                 ,M5         OUT VARCHAR2                       
                                 ,M6         OUT VARCHAR2                       
                                 ,M7         OUT VARCHAR2                       
                                 ,M8         OUT VARCHAR2                       
                                 ,M9         OUT VARCHAR2                       
                                 ,M10        OUT VARCHAR2                       
                                 ,M11        OUT VARCHAR2                       
                                 ,M12        OUT VARCHAR2                       
                                 ,M13        OUT VARCHAR2                       
                                 ,M14        OUT VARCHAR2                       
                                 ,M15        OUT VARCHAR2                       
                                 ,M16        OUT VARCHAR2                       
                                 ,M17        OUT VARCHAR2                       
                                 ,M18        OUT VARCHAR2                       
                                 ,M19        OUT VARCHAR2                       
                                 ,M20        OUT VARCHAR2) IS                   
        ATTRIBUTES  BINARY_INTEGER;                                             
    BEGIN                                                                       
        VALIDATIONNEXTRESULT(                                                   
                 HANDLE, RECID, SET_STAMP, SET_COUNT, PIECENO, MSCA,            
                 M1,  M2,  M3,  M4,  M5,                                        
                 M6,  M7,  M8,  M9,  M10,                                       
                 M11, M12, M13, M14, M15,                                       
                 M16, M17, M18, M19, M20, ATTRIBUTES );                         
    END;                                                                        
                                                                                
  PROCEDURE VALIDATIONNEXTRESULT( HANDLE     OUT VARCHAR2                       
                                 ,RECID      OUT NUMBER                         
                                 ,SET_STAMP  OUT NUMBER                         
                                 ,SET_COUNT  OUT NUMBER                         
                                 ,PIECENO    OUT NUMBER                         
                                 ,MSCA       OUT BINARY_INTEGER                 
                                 ,M1         OUT VARCHAR2                       
                                 ,M2         OUT VARCHAR2                       
                                 ,M3         OUT VARCHAR2                       
                                 ,M4         OUT VARCHAR2                       
                                 ,M5         OUT VARCHAR2                       
                                 ,M6         OUT VARCHAR2                       
                                 ,M7         OUT VARCHAR2                       
                                 ,M8         OUT VARCHAR2                       
                                 ,M9         OUT VARCHAR2                       
                                 ,M10        OUT VARCHAR2                       
                                 ,M11        OUT VARCHAR2                       
                                 ,M12        OUT VARCHAR2                       
                                 ,M13        OUT VARCHAR2                       
                                 ,M14        OUT VARCHAR2                       
                                 ,M15        OUT VARCHAR2                       
                                 ,M16        OUT VARCHAR2                       
                                 ,M17        OUT VARCHAR2                       
                                 ,M18        OUT VARCHAR2                       
                                 ,M19        OUT VARCHAR2                       
                                 ,M20        OUT VARCHAR2                       
                                 ,ATTRIBUTES OUT BINARY_INTEGER) IS             
    BEGIN                                                                       
        ICDSTART(149);                                                          
        KRBIVALN(HANDLE, RECID, SET_STAMP, SET_COUNT, PIECENO, MSCA,            
                 M1,  M2,  M3,  M4,  M5,                                        
                 M6,  M7,  M8,  M9,  M10,                                       
                 M11, M12, M13, M14, M15,                                       
                 M16, M17, M18, M19, M20, ATTRIBUTES );                         
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIVALE;                                                           
  PRAGMA INTERFACE (C, KRBIVALE);                                               
                                                                                
                                                                                
  PROCEDURE VALIDATIONEND IS                                                    
    BEGIN                                                                       
        ICDSTART(150);                                                          
        KRBIVALE;                                                               
        ICDFINISH;                                                              
    EXCEPTION                                                                   
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIURT (RECTYPE   IN BINARY_INTEGER,                               
                     RECID     IN NUMBER,                                       
                     STAMP     IN NUMBER,                                       
                     FCODE     IN BINARY_INTEGER);                              
                                                                                
  PRAGMA INTERFACE (C, KRBIURT);                                                
                                                                                
  PROCEDURE CLEARRECOVERYDESTFLAG(RECTYPE IN BINARY_INTEGER,                    
                                  RECID   IN NUMBER,                            
                                  STAMP   IN NUMBER)                            
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(136);                                                             
     KRBIURT(RECTYPE, RECID, STAMP, 1);                                         
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBINBEG(NEWDBNAME   IN  VARCHAR2,                                  
                     OLDDBNAME   IN  VARCHAR2,                                  
                     NEWDBID     IN  NUMBER,                                    
                     OLDDBID     IN  NUMBER,                                    
                     DOREVERT    IN  BINARY_INTEGER,                            
                     DORESTART   IN  BINARY_INTEGER,                            
                     EVENTS      IN  NUMBER);                                   
                                                                                
  PRAGMA INTERFACE (C, KRBINBEG);                                               
                                                                                
  PROCEDURE NIDBEGIN(NEWDBNAME   IN  VARCHAR2,                                  
                     OLDDBNAME   IN  VARCHAR2,                                  
                     NEWDBID     IN  NUMBER,                                    
                     OLDDBID     IN  NUMBER,                                    
                     DOREVERT    IN  BINARY_INTEGER,                            
                     DORESTART   IN  BINARY_INTEGER,                            
                     EVENTS      IN  NUMBER) IS                                 
     NDBNAME   VARCHAR2(16);                                                    
     NDBNAMEL  VARCHAR2(16) NOT NULL := ' ';                                    
     ODBNAMEL  VARCHAR2(16) NOT NULL := ' ';                                    
     NEWDBIDL  NUMBER NOT NULL := 0;                                            
     OLDDBIDL  NUMBER NOT NULL := 0;                                            
     REVERTL   BINARY_INTEGER NOT NULL := 0;                                    
     RESTARTL  BINARY_INTEGER NOT NULL := 0;                                    
     EVENTSL   NUMBER NOT NULL := 0;                                            
  BEGIN                                                                         
     ICDSTART(137, CHKEVENTS=>TRUE);                                            
                                                                                
     NDBNAMEL := NEWDBNAME;                                                     
     ODBNAMEL := OLDDBNAME;                                                     
     IF ODBNAMEL = NDBNAMEL THEN                                                
        NDBNAME := NULL;                                                        
     ELSE                                                                       
        NDBNAME := NEWDBNAME;                                                   
     END IF;                                                                    
     NEWDBIDL := NEWDBID;                                                       
     OLDDBIDL := OLDDBID;                                                       
     REVERTL  := DOREVERT;                                                      
     RESTARTL := DORESTART;                                                     
     EVENTSL  := EVENTS;                                                        
     KRBINBEG(NDBNAME, OLDDBNAME, NEWDBID, OLDDBID, DOREVERT, DORESTART,        
              EVENTS);                                                          
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBINGNI(DBNAME   IN  VARCHAR2,                                     
                     NDBID   OUT  NUMBER);                                      
                                                                                
  PRAGMA INTERFACE (C, KRBINGNI);                                               
                                                                                
  PROCEDURE NIDGETNEWDBID(DBNAME    IN  VARCHAR2,                               
                          NDBID    OUT  NUMBER) IS                              
     DBNAMEL  VARCHAR2(16) NOT NULL := ' ';                                     
  BEGIN                                                                         
     ICDSTART(138);                                                             
                                                                                
     DBNAMEL := DBNAME;                                                         
     KRBINGNI(DBNAME, NDBID);                                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBINEND;                                                           
                                                                                
  PRAGMA INTERFACE (C, KRBINEND);                                               
                                                                                
  PROCEDURE NIDEND IS                                                           
  BEGIN                                                                         
     ICDSTART(139);                                                             
     KRBINEND;                                                                  
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBINPCF(CHGDBID     OUT BINARY_INTEGER,                            
                     CHGDBNAME   OUT BINARY_INTEGER);                           
                                                                                
  PRAGMA INTERFACE (C, KRBINPCF);                                               
                                                                                
  PROCEDURE NIDPROCESSCF(CHGDBID     OUT BINARY_INTEGER,                        
                         CHGDBNAME   OUT BINARY_INTEGER) IS                     
  BEGIN                                                                         
     ICDSTART(140);                                                             
     KRBINPCF(CHGDBID, CHGDBNAME);                                              
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBINPDF(FNO          IN NUMBER,                                    
                     ISTEMP       IN BINARY_INTEGER,                            
                     SKIPPED     OUT BINARY_INTEGER,                            
                     CHGDBID     OUT BINARY_INTEGER,                            
                     CHGDBNAME   OUT BINARY_INTEGER);                           
                                                                                
  PRAGMA INTERFACE (C, KRBINPDF);                                               
                                                                                
  PROCEDURE NIDPROCESSDF(FNO          IN NUMBER,                                
                         ISTEMP       IN BINARY_INTEGER,                        
                         SKIPPED     OUT BINARY_INTEGER,                        
                         CHGDBID     OUT BINARY_INTEGER,                        
                         CHGDBNAME   OUT BINARY_INTEGER) IS                     
     FNOL     NUMBER NOT NULL := 0;                                             
     ISTEMPL  BINARY_INTEGER NOT NULL := 0;                                     
  BEGIN                                                                         
     ICDSTART(141);                                                             
                                                                                
     FNOL := FNO;                                                               
     ISTEMPL := ISTEMP;                                                         
     KRBINPDF(FNO, ISTEMP, SKIPPED, CHGDBID, CHGDBNAME);                        
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIISOMF(FNAME   IN  VARCHAR2,                                     
                      ISOMF   OUT BOOLEAN,                                      
                      ISASM   OUT BOOLEAN,                                      
                      ISTMPLT OUT BOOLEAN);                                     
                                                                                
  PRAGMA INTERFACE (C, KRBIISOMF);                                              
                                                                                
  PROCEDURE ISFILENAMEOMF(FNAME   IN  VARCHAR2,                                 
                          ISOMF   OUT BOOLEAN,                                  
                          ISASM   OUT BOOLEAN) IS                               
    ISTMPLT   BOOLEAN;                                                          
  BEGIN                                                                         
    ISFILENAMEOMF(FNAME, ISOMF, ISASM, ISTMPLT);                                
  END;                                                                          
                                                                                
                                                                                
  PROCEDURE ISFILENAMEOMF(FNAME   IN  VARCHAR2,                                 
                          ISOMF   OUT BOOLEAN,                                  
                          ISASM   OUT BOOLEAN,                                  
                          ISTMPLT OUT BOOLEAN) IS                               
  BEGIN                                                                         
     ICDSTART(142);                                                             
     IF FNAME IS NULL THEN                                                      
        KRBIRERR(19864, 'File name is NULL');                                   
     END IF;                                                                    
     KRBIISOMF(FNAME, ISOMF, ISASM, ISTMPLT);                                   
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
  PROCEDURE KRBICLRL;                                                           
                                                                                
  PRAGMA INTERFACE (C, KRBICLRL);                                               
                                                                                
  PROCEDURE CLEARONLINELOGNAMES                                                 
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(145);                                                             
     KRBICLRL();                                                                
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PRAGMA INTERFACE (C, KRBITRC);                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PRAGMA INTERFACE (C, KRBIWTRC);                                               
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRCDF(FNO      IN NUMBER,                                        
                    NEWOMF    IN BOOLEAN,                                       
                    RECOVERY  IN BOOLEAN,                                       
                    FNAME     IN VARCHAR2 DEFAULT NULL);                        
  PRAGMA INTERFACE (C, KRBIRCDF);                                               
                                                                                
  PROCEDURE CREATEDATAFILE(FNO      IN NUMBER,                                  
                           NEWOMF   IN BOOLEAN,                                 
                           RECOVERY IN BOOLEAN,                                 
                           FNAME    IN VARCHAR2 DEFAULT NULL) IS                
     IFNO      NUMBER;                                                          
     INEWOMF   BOOLEAN;                                                         
     IRECOVERY BOOLEAN;                                                         
  BEGIN                                                                         
     ICDSTART(151);                                                             
                                                                                
     IFNO := FNO;                                                               
     IF FNO IS NULL THEN                                                        
        KRBIRERR(19864, 'fno is NULL');                                         
     END IF;                                                                    
     INEWOMF := NEWOMF;                                                         
     IRECOVERY := RECOVERY;                                                     
     KRBIRCDF(IFNO, INEWOMF, IRECOVERY, FNAME);                                 
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRECFS(RECORD_TYPE IN  BINARY_INTEGER);                          
                                                                                
  PRAGMA INTERFACE (C, KRBIRECFS);                                              
                                                                                
  PROCEDURE RESETCFILESECTION(RECORD_TYPE IN BINARY_INTEGER) IS                 
  BEGIN                                                                         
     ICDSTART(152);                                                             
     KRBIRECFS(RECORD_TYPE);                                                    
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISWTF(TSNUM       IN NUMBER,                                     
                     TSNAME      IN VARCHAR2,                                   
                     TFNUM       IN NUMBER,                                     
                     TFNAME      IN VARCHAR2,                                   
                     CREATE_TIME IN DATE,                                       
                     CREATE_SCN  IN NUMBER,                                     
                     BLOCKS      IN NUMBER,                                     
                     BLOCKSIZE   IN BINARY_INTEGER,                             
                     RFNUM       IN NUMBER,                                     
                     EXTON       IN BOOLEAN,                                    
                     ISSFT       IN BOOLEAN,                                    
                     MAXSIZE     IN NUMBER,                                     
                     NEXTSIZE    IN NUMBER);                                    
                                                                                
  PRAGMA INTERFACE (C, KRBISWTF);                                               
                                                                                
  PROCEDURE SWITCHTEMPFILE(TSNUM       IN NUMBER,                               
                           TSNAME      IN VARCHAR2,                             
                           TFNUM       IN NUMBER,                               
                           TFNAME      IN VARCHAR2,                             
                           CREATE_TIME IN DATE,                                 
                           CREATE_SCN  IN NUMBER,                               
                           BLOCKS      IN NUMBER,                               
                           BLOCKSIZE   IN BINARY_INTEGER,                       
                           RFNUM       IN NUMBER,                               
                           EXTON       IN BOOLEAN,                              
                           ISSFT       IN BOOLEAN,                              
                           MAXSIZE     IN NUMBER,                               
                           NEXTSIZE    IN NUMBER) IS                            
  BEGIN                                                                         
     ICDSTART(153);                                                             
     KRBISWTF(TSNUM, TSNAME, TFNUM, TFNAME, CREATE_TIME, CREATE_SCN,            
              BLOCKS, BLOCKSIZE, RFNUM, EXTON, ISSFT, MAXSIZE, NEXTSIZE);       
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIGTSC( TSCNAME       IN VARCHAR2 DEFAULT NULL                    
                     ,PFFORMAT      IN VARCHAR2 DEFAULT NULL                    
                     ,RMTSCNAME     IN VARCHAR2 DEFAULT NULL                    
                     ,PFNAME        OUT VARCHAR2                                
                     ,NEWTSCFNAME   OUT VARCHAR2                                
                     ,NEWRMTSCNAME  OUT VARCHAR2                                
                     ,PARALLELISM   IN NUMBER);                                 
                                                                                
  PRAGMA INTERFACE (C, KRBIGTSC);                                               
                                                                                
  PROCEDURE GENTRANSPORTSCRIPT( TSCNAME       IN VARCHAR2 DEFAULT NULL          
                               ,PFFORMAT      IN VARCHAR2 DEFAULT NULL          
                               ,RMTSCNAME     IN VARCHAR2 DEFAULT NULL          
                               ,PFNAME        OUT VARCHAR2                      
                               ,NEWTSCNAME    OUT VARCHAR2                      
                               ,NEWRMTSCNAME  OUT VARCHAR2) IS                  
  BEGIN                                                                         
     GENTRANSPORTSCRIPT(TSCNAME, PFFORMAT, RMTSCNAME,                           
                        PFNAME, NEWTSCNAME, NEWRMTSCNAME, NULL);                
  END;                                                                          
                                                                                
  PROCEDURE GENTRANSPORTSCRIPT( TSCNAME       IN VARCHAR2 DEFAULT NULL          
                               ,PFFORMAT      IN VARCHAR2 DEFAULT NULL          
                               ,RMTSCNAME     IN VARCHAR2 DEFAULT NULL          
                               ,PFNAME        OUT VARCHAR2                      
                               ,NEWTSCNAME    OUT VARCHAR2                      
                               ,NEWRMTSCNAME  OUT VARCHAR2                      
                               ,PARALLELISM   IN NUMBER) IS                     
  BEGIN                                                                         
     ICDSTART(154);                                                             
     KRBIGTSC(TSCNAME, PFFORMAT, RMTSCNAME,                                     
              PFNAME, NEWTSCNAME, NEWRMTSCNAME,                                 
              PARALLELISM);                                                     
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBITDBLK(NEWDBNAME IN VARCHAR2 DEFAULT NULL);                      
                                                                                
  PRAGMA INTERFACE (C, KRBITDBLK);                                              
                                                                                
  PROCEDURE TRANSPORTDBLOCK(NEWDBNAME IN VARCHAR2 DEFAULT NULL) IS              
  BEGIN                                                                         
     ICDSTART(155);                                                             
     KRBITDBLK(NEWDBNAME);                                                      
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBITDBUNLK;                                                        
                                                                                
  PRAGMA INTERFACE (C, KRBITDBUNLK);                                            
                                                                                
  PROCEDURE TRANSPORTDBUNLOCK IS                                                
  BEGIN                                                                         
     ICDSTART(156);                                                             
     KRBITDBUNLK;                                                               
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISBTV( ISORACLE      OUT BOOLEAN                                 
                     ,VERSION       OUT VARCHAR2);                              
                                                                                
  PRAGMA INTERFACE (C, KRBISBTV);                                               
                                                                                
  PROCEDURE ORACLESBTVERSION( ISORACLE      OUT BOOLEAN                         
                             ,VERSION       OUT VARCHAR2) IS                    
  BEGIN                                                                         
     ICDSTART(157);                                                             
     KRBISBTV(ISORACLE, VERSION);                                               
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISPRM(P0 IN NUMBER   DEFAULT NULL,                               
                     P1 IN NUMBER   DEFAULT NULL,                               
                     P2 IN NUMBER   DEFAULT NULL,                               
                     P3 IN NUMBER   DEFAULT NULL,                               
                     P4 IN NUMBER   DEFAULT NULL,                               
                     P5 IN VARCHAR2 DEFAULT NULL,                               
                     P6 IN VARCHAR2 DEFAULT NULL,                               
                     P7 IN VARCHAR2 DEFAULT NULL,                               
                     P8 IN VARCHAR2 DEFAULT NULL,                               
                     P9 IN VARCHAR2 DEFAULT NULL);                              
  PRAGMA INTERFACE (C, KRBISPRM);                                               
                                                                                
  PROCEDURE SETPARMS(P0 IN NUMBER   DEFAULT NULL,                               
                     P1 IN NUMBER   DEFAULT NULL,                               
                     P2 IN NUMBER   DEFAULT NULL,                               
                     P3 IN NUMBER   DEFAULT NULL,                               
                     P4 IN NUMBER   DEFAULT NULL,                               
                     P5 IN VARCHAR2 DEFAULT NULL,                               
                     P6 IN VARCHAR2 DEFAULT NULL,                               
                     P7 IN VARCHAR2 DEFAULT NULL,                               
                     P8 IN VARCHAR2 DEFAULT NULL,                               
                     P9 IN VARCHAR2 DEFAULT NULL) IS                            
  BEGIN                                                                         
     ICDSTART(158);                                                             
     KRBISPRM(P0, P1, P2, P3, P4, P5, P6, P7, P8, P9);                          
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE SETTABLESPACEATTR(CODE  IN NUMBER,                                  
                              TSID  IN  BINARY_INTEGER,                         
                              CLEAR IN  BINARY_INTEGER,                         
                              ONOFF IN  BINARY_INTEGER) IS                      
  BEGIN                                                                         
     ICDSTART(159);                                                             
     KRBITSAT(CODE, TSID, CLEAR, ONOFF);                                        
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIGDGN(FNAME IN VARCHAR2) RETURN VARCHAR2;                         
  PRAGMA INTERFACE (C, KRBIGDGN);                                               
                                                                                
  FUNCTION GETDISKGROUPNAME(FNAME IN VARCHAR2) RETURN VARCHAR2 IS               
  IFNAME  VARCHAR2(512) NOT NULL := ' ';                                        
  OFNAME  VARCHAR2(31);                                                         
  BEGIN                                                                         
     ICDSTART(160);                                                             
     IFNAME := FNAME;                                                           
     OFNAME := KRBIGDGN(FNAME);                                                 
     ICDFINISH;                                                                 
     RETURN OFNAME;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
       ICDFINISH;                                                               
       RAISE;                                                                   
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIPCGN( PARMID IN  BINARY_INTEGER                                 
                     ,VALUE  OUT BINARY_INTEGER);                               
                                                                                
  PRAGMA INTERFACE (C, KRBIPCGN);                                               
                                                                                
  PROCEDURE PIECECONTEXTGETNUMBER( PARMID IN  BINARY_INTEGER                    
                                  ,VALUE  OUT BINARY_INTEGER) IS                
  BEGIN                                                                         
        ICDSTART(161);                                                          
        KRBIPCGN(PARMID, VALUE);                                                
        ICDFINISH;                                                              
  EXCEPTION                                                                     
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBINETTRANSFER(NETALIAS    IN  VARCHAR2,                            
                           USERNAME    IN  VARCHAR2,                            
                           PASSWD      IN  VARCHAR2,                            
                           ROLE        IN  VARCHAR2,                            
                           SRCFILE     IN  VARCHAR2,                            
                           DESTFILE    IN  VARCHAR2,                            
                           OPERATION   IN  VARCHAR2,                            
                           FTYPE_CHECK IN  BOOLEAN,                             
                           RETCODE     OUT NUMBER)                              
  RETURN BOOLEAN;                                                               
  PRAGMA INTERFACE (C, KRBINETTRANSFER);                                        
                                                                                
  FUNCTION NETWORKFILETRANSFER(DBNAME      IN  VARCHAR2                         
                              ,USERNAME    IN  VARCHAR2 DEFAULT NULL            
                              ,PASSWD      IN  VARCHAR2 DEFAULT NULL            
                              ,SRCFILE     IN  VARCHAR2                         
                              ,DESTFILE    IN  VARCHAR2                         
                              ,OPERATION   IN  VARCHAR2)                        
  RETURN BOOLEAN IS                                                             
     RETCODE    NUMBER;                                                         
  BEGIN                                                                         
     RETURN NETWORKFILETRANSFER(DBNAME     => DBNAME,                           
                                USERNAME   => USERNAME,                         
                                PASSWD     => PASSWD,                           
                                ROLE       => NULL,                             
                                SRCFILE    => SRCFILE,                          
                                DESTFILE   => DESTFILE,                         
                                OPERATION  => OPERATION,                        
                                RETCODE    => RETCODE);                         
  END;                                                                          
                                                                                
  FUNCTION NETWORKFILETRANSFER(DBNAME      IN  VARCHAR2                         
                              ,USERNAME    IN  VARCHAR2 DEFAULT NULL            
                              ,PASSWD      IN  VARCHAR2 DEFAULT NULL            
                              ,ROLE        IN  VARCHAR2                         
                              ,SRCFILE     IN  VARCHAR2                         
                              ,DESTFILE    IN  VARCHAR2                         
                              ,OPERATION   IN  VARCHAR2                         
                              ,RETCODE     OUT NUMBER)                          
  RETURN BOOLEAN IS                                                             
  BEGIN                                                                         
     RETURN NETWORKFILETRANSFER(DBNAME      => DBNAME,                          
                                USERNAME    => USERNAME,                        
                                PASSWD      => PASSWD,                          
                                ROLE        => ROLE,                            
                                SRCFILE     => SRCFILE,                         
                                DESTFILE    => DESTFILE,                        
                                OPERATION   => OPERATION,                       
                                FTYPE_CHECK => TRUE,                            
                                RETCODE     => RETCODE);                        
  END;                                                                          
                                                                                
  FUNCTION NETWORKFILETRANSFER(DBNAME      IN  VARCHAR2                         
                              ,USERNAME    IN  VARCHAR2 DEFAULT NULL            
                              ,PASSWD      IN  VARCHAR2 DEFAULT NULL            
                              ,ROLE        IN  VARCHAR2                         
                              ,SRCFILE     IN  VARCHAR2                         
                              ,DESTFILE    IN  VARCHAR2                         
                              ,OPERATION   IN  VARCHAR2                         
                              ,FTYPE_CHECK IN  BOOLEAN                          
                              ,RETCODE     OUT NUMBER)                          
  RETURN BOOLEAN IS                                                             
     STATUS     BOOLEAN;                                                        
     INETALIAS  VARCHAR2(1000)  NOT NULL := ' ';                                
     IUSERNAME  VARCHAR2(31);                                                   
     IPASSWD    VARCHAR2(31);                                                   
     IROLE      VARCHAR2(513);                                                  
     ISRCFILE   VARCHAR2(513) NOT NULL := ' ';                                  
     IDESTFILE  VARCHAR2(513) NOT NULL := ' ';                                  
     IOPERATION VARCHAR2(513) NOT NULL := ' ';                                  
     IFTYPE_CHECK BOOLEAN;                                                      
  BEGIN                                                                         
     ICDSTART(162);                                                             
     INETALIAS    := DBNAME;                                                    
     IUSERNAME    := USERNAME;                                                  
     IPASSWD      := PASSWD;                                                    
     IROLE        := ROLE;                                                      
     ISRCFILE     := SRCFILE;                                                   
     IDESTFILE    := DESTFILE;                                                  
     IOPERATION   := OPERATION;                                                 
     IFTYPE_CHECK := FTYPE_CHECK;                                               
     STATUS := KRBINETTRANSFER(NETALIAS    => INETALIAS,                        
                               USERNAME    => IUSERNAME,                        
                               PASSWD      => IPASSWD,                          
                               ROLE        => IROLE,                            
                               SRCFILE     => ISRCFILE,                         
                               DESTFILE    => IDESTFILE,                        
                               OPERATION   => IOPERATION,                       
                               FTYPE_CHECK => IFTYPE_CHECK,                     
                               RETCODE     => RETCODE);                         
     ICDFINISH;                                                                 
     RETURN STATUS;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
     ICDFINISH;                                                                 
     RAISE;                                                                     
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE INCREMENTRECORDSTAMP (RECTYPE IN BINARY_INTEGER,                    
                                  RECID   IN NUMBER,                            
                                  STAMP   IN NUMBER)                            
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(163);                                                             
     KRBIURT(RECTYPE, RECID, STAMP, 2);                                         
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
  PROCEDURE VSSBACKEDRECORD (RECTYPE IN BINARY_INTEGER,                         
                             RECID   IN NUMBER,                                 
                             STAMP   IN NUMBER)                                 
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(163);                                                             
     KRBIURT(RECTYPE, RECID, STAMP, 3);                                         
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PRAGMA INTERFACE (C, KRBIOVAC);                                               
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PRAGMA INTERFACE (C, KRBIRERR);                                               
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE FAULT_INJECTOR(FUNCNO IN NUMBER,                                    
                           FUNCERR IN NUMBER,                                   
                           FUNCCOUNTER IN NUMBER DEFAULT 1) IS                  
  BEGIN                                                                         
     ICDSTART(164);                                                             
     GFAULTFUNCNO := FUNCNO;                                                    
     GFAULTFUNCERR := FUNCERR;                                                  
     GFAULTFUNCCOUNTER := FUNCCOUNTER;                                          
     IF (GTRACEENABLED <> 0) THEN                                               
        KRBIWTRC('Fault injection for function: '||TO_CHAR(FUNCNO)||            
                 ' will return fake error: '||TO_CHAR(FUNCERR)||                
                 ' after '||TO_CHAR(FUNCCOUNTER)||' calls');                    
     END IF;                                                                    
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIIMSB( DFNUMBER      IN  NUMBER                                  
                     ,FILE_SIZE     OUT NUMBER                                  
                     ,SET_STAMP     OUT NUMBER                                  
                     ,SET_COUNT     OUT NUMBER);                                
                                                                                
  PRAGMA INTERFACE (C, KRBIIMSB);                                               
                                                                                
  PROCEDURE INITMSB( DFNUMBER      IN   NUMBER                                  
                    ,FILE_SIZE     OUT  NUMBER                                  
                    ,SET_STAMP     OUT  NUMBER                                  
                    ,SET_COUNT     OUT  NUMBER) IS                              
  BEGIN                                                                         
     ICDSTART(165);                                                             
     KRBIIMSB(DFNUMBER, FILE_SIZE, SET_STAMP, SET_COUNT);                       
     ICDFINISH;                                                                 
  EXCEPTION WHEN OTHERS THEN ICDFINISH; RAISE;                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBISMSB( DFNUMBER      IN  NUMBER                                  
                     ,SECTION_SIZE  IN  NUMBER                                  
                     ,FIRST_SECTION IN  NUMBER                                  
                     ,SECTION_COUNT IN  NUMBER                                  
                     ,SET_STAMP     IN  NUMBER                                  
                     ,SET_COUNT     IN  NUMBER                                  
                     ,PIECENO       IN  NUMBER                                  
                     ,PIECECNT      IN  NUMBER);                                
                                                                                
  PRAGMA INTERFACE (C, KRBISMSB);                                               
                                                                                
  PROCEDURE SETMSB( DFNUMBER      IN  NUMBER                                    
                   ,SECTION_SIZE  IN  NUMBER                                    
                   ,FIRST_SECTION IN  NUMBER                                    
                   ,SECTION_COUNT IN  NUMBER                                    
                   ,SET_STAMP     IN  NUMBER                                    
                   ,SET_COUNT     IN  NUMBER                                    
                   ,PIECENO       IN  NUMBER                                    
                   ,PIECECNT      IN  NUMBER) IS                                
  BEGIN                                                                         
     ICDSTART(166);                                                             
     KRBISMSB(DFNUMBER, SECTION_SIZE, FIRST_SECTION, SECTION_COUNT,             
              SET_STAMP, SET_COUNT, PIECENO, PIECECNT);                         
     ICDFINISH;                                                                 
  EXCEPTION WHEN OTHERS THEN ICDFINISH; RAISE;                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIIMSR(DFNUMBER IN NUMBER, FNAME OUT VARCHAR2);                   
                                                                                
  PRAGMA INTERFACE (C, KRBIIMSR);                                               
                                                                                
  PROCEDURE INITMSR(DFNUMBER IN NUMBER, FNAME OUT VARCHAR2) IS                  
  BEGIN                                                                         
     ICDSTART(175);                                                             
     KRBIIMSR(DFNUMBER, FNAME);                                                 
     ICDFINISH;                                                                 
  EXCEPTION WHEN OTHERS THEN ICDFINISH; RAISE;                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIARCFN(THREAD   IN NUMBER                                        
                     ,SEQUENCE IN NUMBER                                        
                     ,RLS_ID   IN NUMBER                                        
                     ,ARCNAME  OUT VARCHAR2);                                   
                                                                                
  PRAGMA INTERFACE (C, KRBIARCFN);                                              
                                                                                
  PROCEDURE GETARCFILENAME( THREAD   IN NUMBER                                  
                           ,SEQUENCE IN NUMBER                                  
                           ,RLS_ID   IN NUMBER                                  
                           ,ARCNAME  OUT VARCHAR2) IS                           
  BEGIN                                                                         
        ICDSTART(168);                                                          
        KRBIARCFN(THREAD, SEQUENCE, RLS_ID, ARCNAME);                           
        ICDFINISH;                                                              
  EXCEPTION                                                                     
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIBRF( LIMITSCN    IN NUMBER                                      
                    ,RESTOREDNUM OUT BINARY_INTEGER);                           
                                                                                
  PRAGMA INTERFACE (C, KRBIBRF);                                                
                                                                                
  PROCEDURE BMRRESTOREFROMFLASHBACK( LIMITSCN    IN NUMBER                      
                                    ,RESTOREDNUM OUT BINARY_INTEGER) IS         
  BEGIN                                                                         
        ICDSTART(169);                                                          
        KRBIBRF(LIMITSCN, RESTOREDNUM);                                         
        ICDFINISH;                                                              
  EXCEPTION                                                                     
        WHEN OTHERS THEN                                                        
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIBLKSTAT(FIRST      IN  BOOLEAN                                   
                      ,FILETYPE   OUT BINARY_INTEGER                            
                      ,DFNUMBER   OUT NUMBER                                    
                      ,THREAD     OUT BINARY_INTEGER                            
                      ,SEQUENCE   OUT NUMBER                                    
                      ,HIGHSCN    OUT NUMBER                                    
                      ,EXAMINED   OUT NUMBER                                    
                      ,CORRUPT    OUT NUMBER                                    
                      ,EMPTY      OUT NUMBER                                    
                      ,DATA_PROC  OUT NUMBER                                    
                      ,DATA_FAIL  OUT NUMBER                                    
                      ,INDEX_PROC OUT NUMBER                                    
                      ,INDEX_FAIL OUT NUMBER                                    
                      ,OTHER_PROC OUT NUMBER                                    
                      ,OTHER_FAIL OUT NUMBER)                                   
  RETURN BOOLEAN;                                                               
  PRAGMA INTERFACE (C, KRBIBLKSTAT);                                            
                                                                                
  PROCEDURE GETBLOCKSTAT(BLOCKSTATTABLE OUT BLOCKSTATTABLE_T)                   
  IS                                                                            
     FIRST    BOOLEAN := TRUE;                                                  
     BLOCKSTAT BLOCKSTAT_T;                                                     
  BEGIN                                                                         
     ICDSTART(170);                                                             
     BLOCKSTATTABLE.DELETE;                                                     
     LOOP                                                                       
        EXIT WHEN NOT KRBIBLKSTAT(                                              
                           FIRST      => FIRST                                  
                          ,FILETYPE   => BLOCKSTAT.FILETYPE                     
                          ,DFNUMBER   => BLOCKSTAT.DFNUMBER                     
                          ,THREAD     => BLOCKSTAT.THREAD                       
                          ,SEQUENCE   => BLOCKSTAT.SEQUENCE                     
                          ,HIGHSCN    => BLOCKSTAT.HIGHSCN                      
                          ,EXAMINED   => BLOCKSTAT.EXAMINED                     
                          ,CORRUPT    => BLOCKSTAT.CORRUPT                      
                          ,EMPTY      => BLOCKSTAT.EMPTY                        
                          ,DATA_PROC  => BLOCKSTAT.DATA_PROC                    
                          ,DATA_FAIL  => BLOCKSTAT.DATA_FAIL                    
                          ,INDEX_PROC => BLOCKSTAT.INDEX_PROC                   
                          ,INDEX_FAIL => BLOCKSTAT.INDEX_FAIL                   
                          ,OTHER_PROC => BLOCKSTAT.OTHER_PROC                   
                          ,OTHER_FAIL => BLOCKSTAT.OTHER_FAIL);                 
        FIRST := FALSE;                                                         
        BLOCKSTATTABLE(BLOCKSTATTABLE.COUNT + 1) := BLOCKSTAT;                  
     END LOOP;                                                                  
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END GETBLOCKSTAT;                                                             
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIVALBLK(DFNUMBER   IN  NUMBER                                    
                      ,BLKNUMBER  IN  NUMBER                                    
                      ,RANGE      IN  NUMBER);                                  
  PRAGMA INTERFACE (C, KRBIVALBLK);                                             
                                                                                
  PROCEDURE VALIDATEBLOCK(BLOCKRANGETABLE IN BLOCKRANGETABLE_T)                 
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(171);                                                             
     FOR I IN 1..BLOCKRANGETABLE.COUNT LOOP                                     
        KRBIVALBLK(DFNUMBER  => BLOCKRANGETABLE(I).DFNUMBER                     
                  ,BLKNUMBER => BLOCKRANGETABLE(I).BLKNUMBER                    
                  ,RANGE     => BLOCKRANGETABLE(I).RANGE);                      
     END LOOP;                                                                  
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END VALIDATEBLOCK;                                                            
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE IR_ICD_START(FN IN NUMBER) IS                                       
  BEGIN                                                                         
     IF ((FN + 2000) > 4000 OR FN < 1) THEN                                     
        KRBIRERR(19864, 'Invalid function number: '||TO_CHAR(FN));              
     END IF;                                                                    
     ICDSTART(FN + 2000);                                                       
  END IR_ICD_START;                                                             
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE IR_ICD_FINISH IS                                                    
  BEGIN                                                                         
     ICDFINISH;                                                                 
  END IR_ICD_FINISH;                                                            
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIUPHD RETURN BOOLEAN;                                             
  PRAGMA INTERFACE (C, KRBIUPHD);                                               
                                                                                
  FUNCTION UPDATEHEADERS RETURN BOOLEAN                                         
  IS                                                                            
     ALLOK   BOOLEAN;                                                           
  BEGIN                                                                         
     ICDSTART(172);                                                             
     ALLOK := KRBIUPHD;                                                         
     ICDFINISH;                                                                 
     RETURN ALLOK;                                                              
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END UPDATEHEADERS;                                                            
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBI_CLEANUP_BACKUP_RECORDS;                                        
  PRAGMA INTERFACE (C, KRBI_CLEANUP_BACKUP_RECORDS);                            
                                                                                
  PROCEDURE CLEANUPBACKUPRECORDS                                                
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(173);                                                             
     KRBI_CLEANUP_BACKUP_RECORDS;                                               
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END CLEANUPBACKUPRECORDS;                                                     
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBIRDALHD(FNAME            IN  VARCHAR2                            
                      ,FULL_NAME        OUT VARCHAR2                            
                      ,THREAD           OUT NUMBER                              
                      ,SEQUENCE         OUT NUMBER                              
                      ,FIRST_CHANGE     OUT NUMBER                              
                      ,NEXT_CHANGE      OUT NUMBER                              
                      ,RESETLOGS_CHANGE OUT NUMBER                              
                      ,RESETLOGS_TIME   OUT DATE);                              
  PRAGMA INTERFACE (C, KRBIRDALHD);                                             
                                                                                
  PROCEDURE READARCHIVEDLOGHEADER( FNAME            IN  VARCHAR2                
                                  ,FULL_NAME        OUT VARCHAR2                
                                  ,THREAD           OUT NUMBER                  
                                  ,SEQUENCE         OUT NUMBER                  
                                  ,FIRST_CHANGE     OUT NUMBER                  
                                  ,NEXT_CHANGE      OUT NUMBER                  
                                  ,RESETLOGS_CHANGE OUT NUMBER                  
                                  ,RESETLOGS_TIME   OUT DATE)                   
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(174);                                                             
     KRBIRDALHD(FNAME, FULL_NAME, THREAD, SEQUENCE, FIRST_CHANGE,               
                NEXT_CHANGE, RESETLOGS_CHANGE, RESETLOGS_TIME);                 
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END READARCHIVEDLOGHEADER;                                                    
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIRSQLEXEC (SOURCE_DBUNAME IN VARCHAR2,                            
                         SOURCE_CS      IN VARCHAR2,                            
                         STMT           IN VARCHAR2) RETURN VARCHAR2;           
  PRAGMA INTERFACE (C, KRBIRSQLEXEC);                                           
                                                                                
  FUNCTION REMOTESQLEXECUTE (SOURCE_DBUNAME IN VARCHAR2,                        
                             SOURCE_CS      IN VARCHAR2,                        
                             STMT           IN VARCHAR2) RETURN VARCHAR2        
  IS                                                                            
     RETVAL VARCHAR2(1024);                                                     
  BEGIN                                                                         
     ICDSTART(176);                                                             
     RETVAL := KRBIRSQLEXEC(SOURCE_DBUNAME, SOURCE_CS, STMT);                   
     ICDFINISH;                                                                 
     RETURN RETVAL;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END REMOTESQLEXECUTE;                                                         
                                                                                
                                                                                
                                                                                
  PRAGMA INTERFACE (C, KRBI_SAVE_ACTION);                                       
                                                                                
                                                                                
                                                                                
  PRAGMA INTERFACE (C, KRBI_READ_ACTION);                                       
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBI_CLEANUP_FOREIGN_AL;                                            
  PRAGMA INTERFACE (C, KRBI_CLEANUP_FOREIGN_AL);                                
                                                                                
  PROCEDURE CLEANUPFOREIGNARCHIVEDLOGS                                          
  IS                                                                            
  BEGIN                                                                         
     ICDSTART(177);                                                             
     KRBI_CLEANUP_FOREIGN_AL();                                                 
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END CLEANUPFOREIGNARCHIVEDLOGS;                                               
                                                                                
                                                                                
                                                                                
  FUNCTION KRBICKEEPF RETURN BINARY_INTEGER;                                    
  PRAGMA INTERFACE (C, KRBICKEEPF);                                             
                                                                                
  FUNCTION CANKEEPDATAFILES RETURN BINARY_INTEGER                               
  IS                                                                            
     RETVAL    BINARY_INTEGER;                                                  
  BEGIN                                                                         
     ICDSTART(178);                                                             
     RETVAL := KRBICKEEPF;                                                      
     ICDFINISH;                                                                 
     RETURN RETVAL;                                                             
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END CANKEEPDATAFILES;                                                         
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBI_SDBUNAME_TSPITR(DBUNAME IN VARCHAR2);                          
  PRAGMA INTERFACE (C, KRBI_SDBUNAME_TSPITR);                                   
                                                                                
  PROCEDURE SETDBUNIQNAMETSPITR(DBUNAME IN VARCHAR2)                            
  IS                                                                            
                                                                                
  BEGIN                                                                         
     ICDSTART(179);                                                             
     KRBI_SDBUNAME_TSPITR(DBUNAME);                                             
     ICDFINISH;                                                                 
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END SETDBUNIQNAMETSPITR;                                                      
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBIBRPSBY(VALIDATE IN BOOLEAN) RETURN NUMBER;                       
                                                                                
  PRAGMA INTERFACE (C, KRBIBRPSBY);                                             
                                                                                
  FUNCTION BMRRESTOREFROMSTANDBY(VALIDATE IN BOOLEAN) RETURN NUMBER             
  IS                                                                            
     RESTORED NUMBER;                                                           
  BEGIN                                                                         
     ICDSTART(180);                                                             
     RESTORED := KRBIBRPSBY(VALIDATE);                                          
     ICDFINISH;                                                                 
     RETURN RESTORED;                                                           
  EXCEPTION                                                                     
     WHEN OTHERS THEN                                                           
        ICDFINISH;                                                              
        RAISE;                                                                  
  END;                                                                          
                                                                                
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBI_FLASHBACK_CF( FLASHBACKSCN  IN NUMBER );                       
  PRAGMA INTERFACE (C, KRBI_FLASHBACK_CF);                                      
                                                                                
  PROCEDURE FLASHBACKCONTROLFILE( FLASHBACKSCN  IN NUMBER ) IS                  
    BEGIN                                                                       
       ICDSTART(181);                                                           
       KRBI_FLASHBACK_CF(FLASHBACKSCN);                                         
       ICDFINISH;                                                               
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBI_DUPFILEEXISTS RETURN BINARY_INTEGER;                            
  PRAGMA INTERFACE (C, KRBI_DUPFILEEXISTS);                                     
                                                                                
  FUNCTION DUPLICATEFILEEXISTS RETURN BINARY_INTEGER IS                         
       ALLOK BINARY_INTEGER;                                                    
    BEGIN                                                                       
       ICDSTART(182, TRUE);                                                     
       ALLOK := KRBI_DUPFILEEXISTS;                                             
       ICDFINISH;                                                               
       RETURN ALLOK;                                                            
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
                                                                                
  FUNCTION KRBI_GETDUPDCOPY(FNO IN NUMBER,                                      
                            NEWNAME IN VARCHAR2,                                
                            CRESCN IN NUMBER,                                   
                            UNTSCN IN NUMBER,                                   
                            DBID IN NUMBER,                                     
                            DBNAME IN VARCHAR2,                                 
                            FNAME OUT VARCHAR2,                                 
                            CKPSCN OUT NUMBER)                                  
            RETURN BINARY_INTEGER;                                              
  PRAGMA INTERFACE (C, KRBI_GETDUPDCOPY);                                       
                                                                                
  FUNCTION GETDUPLICATEDDATAFILECOPY(FNO IN NUMBER,                             
                                     NEWNAME IN VARCHAR2,                       
                                     CRESCN IN NUMBER,                          
                                     UNTSCN IN NUMBER,                          
                                     DBID IN NUMBER,                            
                                     DBNAME IN VARCHAR2,                        
                                     FNAME OUT VARCHAR2,                        
                                     CKPSCN OUT NUMBER)                         
           RETURN BINARY_INTEGER IS                                             
       FILEOK BINARY_INTEGER;                                                   
       IFNO BINARY_INTEGER NOT NULL := 0;                                       
       ICRESCN NUMBER NOT NULL := 0;                                            
       IUNTSCN NUMBER NOT NULL := 0;                                            
       IDBID NUMBER NOT NULL := 0;                                              
       IDBNAME VARCHAR2(16) NOT NULL := 0;                                      
    BEGIN                                                                       
       ICDSTART(183);                                                           
       IFNO := FNO;                                                             
       ICRESCN := CRESCN;                                                       
       IUNTSCN := UNTSCN;                                                       
       IDBID := DBID;                                                           
       IDBNAME := DBNAME;                                                       
       FILEOK := KRBI_GETDUPDCOPY(FNO, NEWNAME, CRESCN, UNTSCN, DBID, DBNAME,   
                                  FNAME, CKPSCN);                               
       ICDFINISH;                                                               
       RETURN FILEOK;                                                           
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBI_WRTDUPDCOPY(FNO IN NUMBER, FNAME IN VARCHAR2);                 
  PRAGMA INTERFACE (C, KRBI_WRTDUPDCOPY);                                       
                                                                                
  PROCEDURE WRITEDUPLICATEDDATAFILECOPY(FNO IN NUMBER,                          
                                        FNAME IN VARCHAR2) IS                   
       IFNO BINARY_INTEGER NOT NULL := 0;                                       
       IFNAME VARCHAR2(512) NOT NULL := ' ';                                    
    BEGIN                                                                       
       ICDSTART(184);                                                           
       IFNO := FNO;                                                             
       IFNAME := FNAME;                                                         
       KRBI_WRTDUPDCOPY(FNO, FNAME);                                            
       ICDFINISH;                                                               
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
  PROCEDURE KRBI_REMDUPFILE;                                                    
  PRAGMA INTERFACE (C, KRBI_REMDUPFILE);                                        
                                                                                
  PROCEDURE REMOVEDUPLICATEFILE IS                                              
    BEGIN                                                                       
       ICDSTART(185);                                                           
       KRBI_REMDUPFILE;                                                         
       ICDFINISH;                                                               
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
  FUNCTION KRBI_CHKCOMPALG(ALGNAME IN VARCHAR2, ASOFREL IN NUMBER,              
                           ISVALID OUT BINARY_INTEGER,                          
                           MINCOMPAT OUT VARCHAR2)                              
           RETURN BINARY_INTEGER;                                               
  PRAGMA INTERFACE (C, KRBI_CHKCOMPALG);                                        
                                                                                
  FUNCTION CHECKCOMPRESSIONALG(ALGNAME IN VARCHAR2, ASOFREL IN NUMBER,          
                               ISVALID OUT BINARY_INTEGER,                      
                               MINCOMPAT OUT VARCHAR2)                          
           RETURN BINARY_INTEGER IS                                             
       RETVAL NUMBER;                                                           
    BEGIN                                                                       
       ICDSTART(186);                                                           
       IF ALGNAME IS NULL THEN                                                  
          KRBIRERR(19864, 'No algorithm provided');                             
       END IF;                                                                  
       IF ASOFREL IS NULL THEN                                                  
          KRBIRERR(19864, 'No release provided');                               
       END IF;                                                                  
       RETVAL := KRBI_CHKCOMPALG(ALGNAME, ASOFREL, ISVALID, MINCOMPAT);         
       ICDFINISH;                                                               
       RETURN RETVAL;                                                           
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
PROCEDURE KRBI_CLEARCONTROLFILE;                                                
PRAGMA INTERFACE (C, KRBI_CLEARCONTROLFILE);                                    
                                                                                
PROCEDURE CLEARCONTROLFILE IS                                                   
    BEGIN                                                                       
       ICDSTART(187);                                                           
       KRBI_CLEARCONTROLFILE;                                                   
       ICDFINISH;                                                               
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
PROCEDURE KRBI_SWITCH_PRIM_BCT;                                                 
PRAGMA INTERFACE (C, KRBI_SWITCH_PRIM_BCT);                                     
                                                                                
PROCEDURE SWITCH_PRIMARY_BCT IS                                                 
    BEGIN                                                                       
       ICDSTART(188);                                                           
       KRBI_SWITCH_PRIM_BCT;                                                    
       ICDFINISH;                                                               
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
FUNCTION KRBI_GCONNECT_ID(DBUNAME       IN VARCHAR2)                            
                          RETURN VARCHAR2;                                      
PRAGMA INTERFACE (C, KRBI_GCONNECT_ID);                                         
                                                                                
FUNCTION GET_CONNECT_IDENTIFIER(DBUNAME       IN VARCHAR2)                      
                                RETURN VARCHAR2 IS                              
       CONNECT_ID VARCHAR2(256) := 0;                                           
    BEGIN                                                                       
       ICDSTART(189);                                                           
       CONNECT_ID := KRBI_GCONNECT_ID(DBUNAME);                                 
       ICDFINISH;                                                               
       RETURN CONNECT_ID;                                                       
    EXCEPTION                                                                   
       WHEN OTHERS THEN                                                         
         ICDFINISH;                                                             
         RAISE;                                                                 
    END;                                                                        
                                                                                
                                                                                
                                                                                
FUNCTION KRBI_RMAN_USAGE(DISKONLY IN BOOLEAN,                                   
                         NONDISKONLY IN BOOLEAN,                                
                         ENCRYPTED IN BOOLEAN,                                  
                         COMPALG IN VARCHAR2)                                   
RETURN BINARY_INTEGER;                                                          
PRAGMA INTERFACE (C, KRBI_RMAN_USAGE);                                          
                                                                                
FUNCTION RMAN_USAGE(DISKONLY    IN BOOLEAN,                                     
                    NONDISKONLY IN BOOLEAN,                                     
                    ENCRYPTED   IN BOOLEAN,                                     
                    COMPALG     IN VARCHAR2)                                    
RETURN BINARY_INTEGER IS                                                        
    RETVAL NUMBER;                                                              
    IDISKONLY BOOLEAN NOT NULL := DISKONLY;                                     
    INONDISKONLY BOOLEAN NOT NULL := NONDISKONLY;                               
    IENCRYPTED BOOLEAN NOT NULL := ENCRYPTED;                                   
BEGIN                                                                           
    ICDSTART(190);                                                              
    IF DISKONLY AND NONDISKONLY THEN                                            
       KRBIRERR(19864, 'Cannot specify diskonly and nondiskonly at the '||      
                'same time');                                                   
    END IF;                                                                     
                                                                                
    IF ENCRYPTED AND (DISKONLY OR NONDISKONLY OR COMPALG IS NOT NULL) THEN      
       KRBIRERR(19864, 'Cannot specify other parameters when encrypted '||      
                'is used');                                                     
    END IF;                                                                     
                                                                                
    IF COMPALG IS NOT NULL AND (DISKONLY OR NONDISKONLY OR ENCRYPTED) THEN      
       KRBIRERR(19864, 'Cannot specify other parameters when compression '||    
                'algorithm is used');                                           
    END IF;                                                                     
                                                                                
    RETVAL := KRBI_RMAN_USAGE(DISKONLY, NONDISKONLY, ENCRYPTED, COMPALG);       
    ICDFINISH;                                                                  
    RETURN RETVAL;                                                              
EXCEPTION                                                                       
    WHEN OTHERS THEN                                                            
    ICDFINISH;                                                                  
    RAISE;                                                                      
END;                                                                            
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  PRAGMA TIMESTAMP('2001-10-17:13:28:00');                                      
                                                                                
                                                                                
BEGIN                                                                           
  CHECK_VERSION(11,1,0, 'dbms_backup_restore');                                 
                                                                                
  GACTION := KRBI_READ_ACTION();                                                
  GTRACEENABLED := KRBITRC();                                                   
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
  IF (GACTION IS NOT NULL AND LENGTH(GACTION) > 8 AND                           
      (INSTR(GACTION,' STARTED', 8) = 8 OR                                      
       INSTR(GACTION, ' FINISHED', 8) = 8)) THEN                                
     GRPC_COUNT := TO_NUMBER(SUBSTR(GACTION, 1, 7));                            
     IF (GTRACEENABLED <> 0) THEN                                               
        KRBIWTRC('bkrsmain - RPC_Count set to '||                               
                 TO_CHAR(GRPC_COUNT, '0000000MI'));                             
     END IF;                                                                    
     SETACTION(GACTION);                                                        
  ELSIF (GTRACEENABLED <> 0) THEN                                               
     IF (GACTION IS NOT NULL) THEN                                              
        KRBIWTRC('bkrsmain - Non null action '||GACTION);                       
     ELSE                                                                       
        KRBIWTRC('bkrsmain - Action is NULL');                                  
     END IF;                                                                    
  END IF;                                                                       
END;                                                                            

8065 rows selected.

SQL> spool off;
