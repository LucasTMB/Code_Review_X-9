  METHOD corrigir_fae.
    INCLUDE z_code_review_top.

    READ REPORT nome_programa INTO wa_table.

    DATA wa_index_select TYPE i VALUE 0.

    LOOP AT wa_table INTO DATA(wa_text). " Passagem dos dados vindos do report para a tabela interna it_source
      lv_line-index = sy-tabix.
      lv_line-text = wa_text.
      APPEND lv_line TO it_source.
    ENDLOOP.

    CLEAR lv_select_low.

    LOOP AT lt_select INTO DATA(lv_n_linha).
      wa_index_select = wa_index_select + 1.
      READ TABLE lt_select INDEX wa_index_select INTO DATA(ls_select).
      lv_select_low = lv_n_linha-index + lv_select_cont.
      CLEAR it_result.
      CLEAR lv_line.

      IF lv_n_linha-is_selected = abap_true.
        LOOP AT it_source INTO lv_line FROM lv_select_low.
          IF lv_line-text CS '.'.
            APPEND lv_line TO it_result.
            lv_line-text = |* { lv_line-text }|.
            MODIFY it_source FROM lv_line.

            wa_post_high = lv_line-index + 1.
            DATA(wa_ini_comment) = |* Ini - Trecho de código corrigido pelo X-9 - Code Review / Quick Fix |.

            lv_line-text = ' '.
            INSERT lv_line INTO it_result INDEX 1.
            lv_line-text = wa_ini_comment.
            INSERT lv_line INTO it_result INDEX 2.
            lv_line-text = |IF { ls_select-tabela } IS INITIAL . |.
            INSERT lv_line INTO it_result INDEX 3.
            lv_line-text = |  MESSAGE 'Tabela está vazia. Impossível realizar consulta.' TYPE 'E'. |.
            INSERT lv_line INTO it_result INDEX 4.
            lv_line-text = 'ELSE.'.
            INSERT lv_line INTO it_result INDEX 5.
            lv_line-text = ' '.
            INSERT lv_line INTO it_result INDEX 6.

            LOOP AT it_result INTO DATA(ls_result).
              INSERT ls_result INTO it_source INDEX wa_post_high.
              wa_post_high = wa_post_high + 1.
            ENDLOOP.

            DESCRIBE TABLE it_result LINES DATA(lv_count).
            lv_select_cont = lv_select_cont + lv_count.

            lv_line-text = ' '.
            INSERT lv_line INTO it_source INDEX wa_post_high.
            wa_post_high = wa_post_high + 1.
            lv_select_cont = lv_select_cont + 1.
            lv_line-text = 'ENDIF.'.
            INSERT lv_line INTO it_source INDEX wa_post_high.
            wa_post_high = wa_post_high + 1.
            lv_select_cont = lv_select_cont + 1.
            lv_line-text = |* Fim - Trecho de código corrigido pelo X-9 - Code Review / Quick Fix |.
            INSERT lv_line INTO it_source INDEX wa_post_high.
            wa_post_high = wa_post_high + 1.
            lv_select_cont = lv_select_cont + 1.
            lv_line-text = ' '.
            INSERT lv_line INTO it_source INDEX wa_post_high.
            lv_select_cont = lv_select_cont + 1.
            EXIT.
          ELSE.
            APPEND lv_line TO it_result.
            lv_line-text = |* { lv_line-text }|.
            MODIFY it_source FROM lv_line.
          ENDIF.
        ENDLOOP.

        LOOP AT it_source INTO DATA(lv_lines).
          lv_lines-index = sy-tabix.
          MODIFY it_source FROM lv_lines.
        ENDLOOP.
      ENDIF.
    ENDLOOP.


    CLEAR wa_table.
    CLEAR wa_line.
    LOOP AT it_source INTO lv_line.
      wa_line = lv_line-text.
      APPEND wa_line TO wa_table.
    ENDLOOP.

    " Comando que insere a modificação no código fonte
    INSERT REPORT nome_programa FROM wa_table.

  ENDMETHOD.