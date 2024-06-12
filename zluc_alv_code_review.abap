REPORT zluc_alv_code_review.

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: handle_added_function FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.
ENDCLASS.

DATA: lo_event_handler TYPE REF TO lcl_event_handler.

CREATE OBJECT lo_event_handler.

DATA: lo_code_review TYPE REF TO zcl_code_review,
      it_result      TYPE TABLE OF zty_code,
      it_request     TYPE TABLE OF zty_request,
      lv_answer      TYPE c.

DATA: lo_alv              TYPE REF TO cl_salv_table,
      lex_message         TYPE REF TO cx_salv_msg,
      lo_layout_settings  TYPE REF TO cl_salv_layout,
      lo_layout_key       TYPE        salv_s_layout_key,
      lo_columns          TYPE REF TO cl_salv_columns_table,
      lo_column           TYPE REF TO cl_salv_column,
      lex_not_found       TYPE REF TO cx_salv_not_found,
      lo_functions        TYPE REF TO cl_salv_functions_list,
      lo_display_settings TYPE REF TO cl_salv_display_settings.

TYPES: BEGIN OF ty_alv,
         index       TYPE zty_code-index,
         text        TYPE zty_code-text,
         tabela      TYPE zty_code-tabela,
         is_selected TYPE /accgo/e_boolean,
       END OF ty_alv.

DATA: lt_zalv          TYPE TABLE OF ty_alv,
      ls_zalv          TYPE ty_alv,
      lt_altered_lines TYPE TABLE OF ty_alv,
      ls_altered_line  TYPE ty_alv.

CREATE OBJECT lo_code_review.

SELECTION-SCREEN BEGIN OF BLOCK b1.
  PARAMETERS: p_prog TYPE znome_programa.
SELECTION-SCREEN END OF BLOCK b1.

SELECT obj_name
  FROM tadir
  INTO TABLE @DATA(lt_select)
  WHERE obj_name = @p_prog.

IF sy-subrc = 0.
  it_result = lo_code_review->verificar_fae( nome_programa = p_prog ).
  DESCRIBE TABLE it_result LINES DATA(lv_count_erros).
  lt_zalv[] = it_result[].
ELSE.
  MESSAGE 'Programa não encontrado. Por favor, digite novamente.' TYPE 'I'.
  RETURN.
ENDIF.

IF it_result IS INITIAL.
  MESSAGE 'Esse programa não possui Select com For All Entries ou todos For All Entries estão sendo verificados pelo IF' TYPE 'I'.
  RETURN.
ENDIF.

TRY.

    CALL METHOD cl_salv_table=>factory
      IMPORTING
        r_salv_table = lo_alv
      CHANGING
        t_table      = lt_zalv.
    lo_columns = lo_alv->get_columns( ).

    lo_alv->set_screen_status(
      EXPORTING
        report = sy-repid
        pfstatus = 'STANDARD'
        set_functions = lo_alv->c_functions_all
    ).

    SET HANDLER lo_event_handler->handle_added_function FOR lo_alv->get_event( ).

*    DATA(lo_events) = lo_alv->get_event( ).
*    SET HANDLER lo_events->on_user_command FOR lo_events.

  CATCH cx_salv_msg INTO DATA(lo_exception).
    MESSAGE lo_exception TYPE 'I'.
ENDTRY.

*-----------------------------------------------------------------------------------

lo_alv->get_columns( )->set_optimize( abap_true ).
lo_alv->get_display_settings( )->set_striped_pattern( cl_salv_display_settings=>true ).
lo_alv->get_display_settings( )->set_list_header( 'Selects com For All Entries sem verificação.' ).
lo_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).

TRY.
    lo_column = lo_columns->get_column( 'INDEX' ).
    lo_column->set_short_text( 'Linha' ).
    lo_column->set_medium_text( 'Linha Cód' ).
    lo_column->set_long_text( 'Linha do Código' ).

    lo_column = lo_columns->get_column( 'TEXT' ).
    lo_column->set_short_text( 'Código' ).
    lo_column->set_medium_text( 'Código' ).
    lo_column->set_long_text( 'Código' ).

    lo_column = lo_columns->get_column( 'TABELA' ).
    lo_column->set_short_text( 'Tabela' ).
    lo_column->set_medium_text( 'Tabela FAE' ).
    lo_column->set_long_text( 'Tabela do For All Entries' ).

    lo_column = lo_columns->get_column( 'IS_SELECTED' ).
    lo_column->set_short_text( 'Selected?' ).
    lo_column->set_medium_text( 'Foi selecionado?' ).
    lo_column->set_long_text( 'Foi selecionado?' ).
    lo_column->set_visible( abap_false ).
  CATCH cx_salv_not_found INTO lex_not_found.
*      » write some error handling
ENDTRY.

lo_alv->display( ).

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD handle_added_function.
    CASE e_salv_function.
      WHEN '&FIX'.
        DATA(lo_selections) = lo_alv->get_selections( ).
        DATA(lt_selected_rows) = lo_selections->get_selected_rows( ).

        CLEAR lt_altered_lines.
        LOOP AT lt_zalv INTO ls_zalv.
          READ TABLE lt_selected_rows WITH KEY table_line = sy-tabix INTO DATA(lv_selected_row).
          IF sy-subrc = 0.
            ls_zalv-is_selected = abap_true.
          ELSE.
            ls_zalv-is_selected = abap_false.
          ENDIF.
          APPEND ls_zalv TO lt_altered_lines.
        ENDLOOP.

*        SELECT e071~obj_name, e070~strkorr, e070~as4user
*            FROM e071
*            INNER JOIN e070
*            ON e071~trkorr = e070~trkorr
*            INTO TABLE @DATA(it_task)
*            WHERE e071~obj_name = @p_prog
*              AND e070~as4user = @sy-uname.

        SELECT e071~obj_name, e070~strkorr
          FROM e071
          INNER JOIN e070
          ON e071~trkorr = e070~trkorr
          INTO TABLE @DATA(it_req)
          WHERE e071~obj_name = @p_prog.

        READ TABLE it_req INDEX 1 INTO DATA(lv_req).

        SELECT trkorr
          FROM e070
          INTO TABLE @DATA(it_task)
          WHERE as4user = @sy-uname AND strkorr = @lv_req-strkorr.

        IF it_task IS INITIAL.
          READ TABLE it_task INDEX 1 INTO DATA(lv_task).

          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar              = 'Confirmação'
              text_question         = 'É necessário criar uma task na request do programa a ser corrigido. Deseja continuar?'
              text_button_1         = 'Sim'
              text_button_2         = 'Não'
              default_button        = '1'
              display_cancel_button = 'X'
            IMPORTING
              answer                = lv_answer.

          IF lv_answer = '1'.

            lo_code_review->corrigir_fae(
                          nome_programa = p_prog
                          lt_select = lt_altered_lines
                          ).

            DATA(lt_new_result) = lo_code_review->verificar_fae( nome_programa = p_prog ).
            DESCRIBE TABLE lt_new_result LINES DATA(lv_new_count_errors).

            IF sy-subrc = 0.
              IF lv_count_erros <> lv_new_count_errors.
                it_request = lo_code_review->criar_task( nome_programa = p_prog ).

                IF it_request IS NOT INITIAL.
                  READ TABLE it_request INDEX 1 INTO DATA(lv_request).

                  MESSAGE |A Task { lv_request-task } foi criada na Request { lv_request-request }. | TYPE 'I'.
                ENDIF.
                MESSAGE 'Código corrigido com sucesso!' TYPE 'I'.
              ELSE.
                MESSAGE 'Por favor, escolha pelo menos uma das linhas para serem corrigidas.' TYPE 'I'.
              ENDIF.

              LEAVE TO SCREEN 0.
            ENDIF.
          ELSE.
            LEAVE TO SCREEN 0.
          ENDIF.
        ELSE.
          lo_code_review->corrigir_fae(
                            nome_programa = p_prog
                            lt_select = lt_altered_lines
                            ).

          MESSAGE 'Código corrigido com sucesso!' TYPE 'I'.

          LEAVE TO SCREEN 0.
        ENDIF.

      WHEN OTHERS.
        " Código para outras funções
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*lo_alv->get_functions( )->set_all( abap_true ).
*lo_alv->get_display_settings( )->set_list_header( 'Selects com FAE sem verificação' ).
*lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
*  lo_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).

*  lo_alv->get_sorts( )->add_sort( columnname = 'INDEX' sequence = if_salv_c_sort=>sort_up ).
*lo_alv->get_columns( )->set_optimize( abap_true ).