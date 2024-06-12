class ZCL_CODE_REVIEW definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF TY_REQUEST,
      request        TYPE char20,
      task           TYPE char20,
    END OF TY_REQUEST .
  types:
    BEGIN OF ty_code,
         index       TYPE sy-tabix,
         text        TYPE MSSCONSTRING,
         tabela      TYPE MSSCONSTRING,
         is_selected TYPE /ACCGO/E_BOOLEAN,
       END OF ty_code .

  data:
    it_n_line TYPE TABLE OF ty_code .

  methods VERIFICAR_FAE
    importing
      value(NOME_PROGRAMA) type ZNOME_PROGRAMA
    returning
      value(IT_N_LINE) type ZTT_CODE .
  methods CORRIGIR_FAE
    importing
      value(NOME_PROGRAMA) type ZNOME_PROGRAMA
      value(LT_SELECT) type ZTT_CODE .
  methods CRIAR_TASK
    importing
      value(NOME_PROGRAMA) type ZNOME_PROGRAMA
    returning
      value(LT_REQUEST) type ZTT_REQUEST .