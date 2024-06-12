  METHOD verificar_fae.

    INCLUDE z_code_review_top.

    DATA: lt_zline        TYPE TABLE OF ty_code,
          wa_index_tabela TYPE i VALUE 0.

    READ REPORT nome_programa INTO wa_table.

    LOOP AT wa_table INTO DATA(wa_text). " Passagem dos dados vindos do report para a tabela interna it_source
      lv_line-index = sy-tabix.
      lv_line-text = wa_text.
      APPEND lv_line TO it_source.
    ENDLOOP.

*** Ini - Wendsilva e Lubarros - Texto - 27.05.2024 11:00:06 ***

    LOOP AT it_source INTO lv_line.
*** Ini - LUBARROS - Resolução de bug do Select * - 30.05.2024 17:12:34 ***
      IF lv_line-text CS 'SELECT' AND lv_line-text CS '*'.
        SPLIT lv_line-text AT ' ' INTO TABLE lt_string.
        READ TABLE lt_string INDEX 1 INTO lv_ast.

        IF lv_ast = '*'.
          lv_is_comment = abap_true.
        ELSE.
          IF lv_line-text NS '"'.
            lv_select_low  = lv_line-index.
            lv_select_line = lv_line-text.
          ENDIF.
        ENDIF.
      ELSEIF lv_line-text CS 'SELECT' AND lv_line-text NS '*' AND lv_is_comment = abap_false.
        IF lv_line-text NS '"'.
          lv_select_low  = lv_line-index.
          lv_select_line = lv_line-text.
        ENDIF.
      ENDIF.
*** Fim - LUBARROS ***


      IF lv_line-text CS 'FOR ALL ENTRIES' AND lv_line-text NS '*'.
        IF lv_line-text NS '"'.
          lv_for = lv_for + 1.
* Esse trecho serve para pegar o nome da tabela usada no for all entries.
          SPLIT lv_line-text AT ' ' INTO TABLE lt_string.

          LOOP AT lt_string INTO lv_string.
            IF lv_string = 'IN'.
              READ TABLE lt_string INDEX sy-tabix + 1 INTO lv_tabela.

*** Ini - LUBARROS - Resolução de bug do @ na frente da tabela - 30.05.2024 17:13:14 ***
              IF lv_tabela+0(1) = '@'.
                lv_tabela = lv_tabela+1.
              ENDIF.

*              wa_index_tabela = wa_index_tabela + 1.
*              wa_tabelas-index = wa_index_tabela.
              wa_tabelas-tabela = lv_tabela.

              APPEND wa_tabelas TO lt_tabelas.

              lv_end_index = lv_line-index.
*** Fim - LUBARROS ***

              IF sy-subrc = 0.
                EXIT.
              ENDIF.
            ENDIF.
          ENDLOOP.
*** Ini - LUBARROS - Definindo um escopo para o loop que verifica a existência do IF - 30.05.2024 20:13:09 ***
          LOOP AT it_source INTO lv_line FROM lv_start_index TO lv_end_index.
            IF lv_line-text CS 'IF ' AND lv_line-text CS lv_tabela AND lv_line-text NS '*' AND lv_line-text NS 'ENDIF.'.
              IF lv_line-text NS '"'.
                lv_if = lv_if + 1.
                lv_is_if = abap_true.
              ENDIF.
            ELSEIF lv_line-text CS 'FOR ALL ENTRIES' AND lv_line-text NS '*' AND lv_is_if = abap_false.
              IF lv_line-text NS '"'.
                lv_n_line-index = lv_select_low.
                lv_n_line-text  = lv_select_line.
                lv_n_line-tabela = wa_tabelas-tabela.
                APPEND lv_n_line TO lt_zline.
              ENDIF.
            ENDIF.
          ENDLOOP.
          lv_start_index = lv_end_index + 1.
          lv_is_if = abap_false.
*** Fim - LUBARROS ***
        ENDIF.
      ENDIF.

***  ----------------------------------------------------------------------|

      lv_is_comment = abap_false.
    ENDLOOP.

    it_n_line[] = lt_zline[].
  ENDMETHOD.