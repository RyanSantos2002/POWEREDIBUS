import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService()
      : _client = SupabaseClient(
          'https://aslahqzpawlvyrapovzg.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzbGFocXpwYXdsdnlyYXBvdnpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjMyOTM2MDUsImV4cCI6MjAzODg2OTYwNX0.ZeaW35MNL0pQeqKOSuXfOXBwqs9-3TjnZjtdIh_OiGg',
        );

  Future<void> salvarDadosNoSupabase(
    String nome,
    String telefone,
    String cpf,
    String email,
  ) async {
    try {
      print("Tentando salvar dados no Supabase");

      final response = await _client
          .from('user') // Nome da tabela no Supabase
          .insert({
            'name': nome,
            'phone': telefone,
            'cpf': cpf,
            'email': email,
          })
          .execute();

      if (response.error == null) {
        print("Dados salvos com sucesso: ${response.data}");
      } else {
        print("Erro retornado pelo Supabase: ${response.error!.message}");
        print("Detalhes do erro: ${response.error!.details}");
        print("Hint do erro: ${response.error!.hint}");
        throw Exception('Erro ao salvar dados no Supabase: ${response.error!.message}');
      }
    } catch (e) {
      print("Erro no cadastro: $e");
    }
  }
}
