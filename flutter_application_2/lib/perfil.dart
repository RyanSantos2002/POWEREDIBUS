import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.grey[800], // Cor de fundo da AppBar (opcional)
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        color: Colors.grey[900], // Cor de fundo da tela (opcional)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            TextButton(
              onPressed: () {
                // Lógica para alterar a foto
              },
              child: const Text('Alterar foto'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: 'Exemplo Nome',
              decoration: const InputDecoration(
                labelText: 'Nome de Usuário',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: 'email@email.com.br',
              decoration: const InputDecoration(
                labelText: 'E-mail',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: '(99) 99999-9999',
              decoration: const InputDecoration(
                labelText: 'Telefone',
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Lógica para redefinir a senha
              },
              child: const Text('Redefinir senha'),
            ),
          ],
        ),
      ),
    );
  }
}