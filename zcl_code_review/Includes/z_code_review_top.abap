*** Ini - lubarros e wendsilva - Definição da estrutura e variáveis - 27.05.2024 16:27:28 ***

DATA: it_source      TYPE TABLE OF ty_code,         " Código fonte do programa que vai ser alterado
      it_result      TYPE TABLE OF ty_code,         " Tabela interna que vai armazenar bloco que vai ser alterado
      lv_line        TYPE ty_code,                  " Linhas dos códigos de cada tabela interna do tipo ty_code
      wa_table       TYPE TABLE OF string,          " Tabela que vai puxar o código fonte do report e adicionar no it_source
      wa_line        TYPE string,                   " Linha da tabela wa_table
      lv_fase        TYPE i VALUE 0,                " Contador que indica quais funções o código deve seguir
      lv_res_fase    TYPE i VALUE 0,                " Contador que permite a inserção do código corrigido
      lv_is_fae      TYPE bool VALUE abap_false,    " Booleano que verifica se o bloco de código possui for all entries
      lv_is_exec     TYPE bool VALUE abap_false,    " Booleano que verifica se houve mudanças no código fonte
      lv_is_comment  TYPE bool VALUE abap_false,    " Booleano que verifica se a linha atual é um comentário com *
      lv_select_low  TYPE i,                        " Linha onde começa o select
      lv_select_line TYPE string,                   " Linha do select do For All Entries
      lv_select_high TYPE i,                        " Linha onde termina o select
      lv_select_cont TYPE i VALUE 0,                " Contagem de linhas do select
      lv_start_index TYPE i VALUE 1,                " Linha que começa o escopo do Loop de verificação
      lv_end_index   TYPE i.                        " Linha que termina o escopo de verificação

DATA: lv_for         TYPE i VALUE 0,
      lv_if          TYPE i VALUE 0,
      lv_total       TYPE i VALUE 0,
      lv_is_if       TYPE bool VALUE abap_false,
      lv_n_line      TYPE ty_code.

DATA: lt_string      TYPE TABLE OF string,
      lv_string      TYPE string,
      lv_tabela      TYPE string VALUE '*',
      lt_tabelas     TYPE TABLE OF ty_code,
      wa_tabelas     TYPE ty_code,
      lv_ast         TYPE string,
      wa_post_high   TYPE i VALUE 0.


*** Fim - LUBARROS e WENDSILVA ***