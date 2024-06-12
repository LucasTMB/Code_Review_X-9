METHOD criar_task.
   DATA: wa_transport      TYPE char20,
         lt_zrequest       TYPE TABLE OF ty_request,
         ls_zrequest       TYPE ty_request,
         lt_request_header TYPE trwbo_request_headers,
         ls_request_header LIKE LINE OF lt_request_header,
         ls_unclass_task   TYPE e070,
         lv_transtask_rep  TYPE trkorr.

   SELECT e071~obj_name, e070~strkorr
     FROM e071
     INNER JOIN e070
     ON e071~trkorr = e070~trkorr
     INTO TABLE @DATA(it_result)
     WHERE e071~obj_name = @nome_programa.

   IF it_result IS NOT INITIAL.
     READ TABLE it_result INDEX 1 INTO DATA(lv_result).

     CALL FUNCTION 'TRINT_INSERT_NEW_COMM'
       EXPORTING
         wi_kurztext   = 'Task criada pelo Code Review'
         wi_trfunction = 'X'
         iv_username   = sy-uname
         wi_strkorr    = lv_result-strkorr
*        IV_TARSYSTEM  = ' '
         wi_client     = '200'
*        IV_TARDEVCL   = ' '
*        IV_DEVCLASS   = ' '
*        IV_TARLAYER   = ' '
*        WI_PROTECT    = ' '
*        IV_SIMULATION = ' '
*        IV_REPOID     = ' '
       IMPORTING
         we_trkorr     = wa_transport
*        WE_E070       =
*        WE_E07T       =
*        WE_E070C      =
*        ES_E070M      =
*    EXCEPTIONS
*        NO_SYSTEMNAME = 1
*        NO_SYSTEMTYPE = 2
*        NO_AUTHORIZATION        = 3
*        DB_ACCESS_ERROR         = 4
*        FILE_ACCESS_ERROR       = 5
*        ENQUEUE_ERROR = 6
*        NUMBER_RANGE_FULL       = 7
*        INVALID_INPUT = 8
*        OTHERS        = 9
       .

     ls_zrequest-request = lv_result-strkorr.
     ls_zrequest-task    = wa_transport.
     APPEND ls_zrequest TO lt_zrequest.

     lt_request[] = lt_zrequest[].

*     CHECK mv_transtask_rep IS INITIAL.

     CALL FUNCTION 'TR_READ_REQUEST_WITH_TASKS'
       EXPORTING
         iv_trkorr          = wa_transport
       IMPORTING
         et_request_headers = lt_request_header.

     READ TABLE lt_request_header INTO ls_request_header
        WITH KEY trfunction = 'X'        "unclasified
                 trstatus  = 'D'         "changeable
                 as4user    = sy-uname.  "current user

     IF sy-subrc = 0.
       CALL FUNCTION 'ENQUEUE_E_TRKORR'
         EXPORTING
           trkorr       = ls_request_header-trkorr
         EXCEPTIONS
           foreign_lock = 1.

       IF sy-subrc = 0.
*     change task type to repair type
         ls_request_header-trfunction = 'R'.
         MOVE-CORRESPONDING ls_request_header TO ls_unclass_task.
         CALL FUNCTION 'TRINT_MODIFY_COMM'
           EXPORTING
             wi_called_by_editor = ' '
             wi_e070             = ls_unclass_task
*            wi_e07t             =
             wi_lock_sort_flag   = ' '
             wi_save_user        = ' '
             wi_sel_e071         = ' '
             wi_sel_e071k        = ' '
             wi_sel_e07t         = ' '
             wi_sel_e070c        = ' '
             wi_no_client_check  = 'X'
           IMPORTING
             we_e070             = ls_unclass_task.
       ENDIF.
     ENDIF.
   ELSE.
     MESSAGE 'O programa não existe ou está salvo como programa local.' TYPE 'I'.
   ENDIF.



 ENDMETHOD.