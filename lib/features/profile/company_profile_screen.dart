import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/company_profile_service.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _streetNumberCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String? _logoUrl;
  String? _signatureUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final svc = ref.read(companyProfileServiceProvider);
      final p = await svc.getProfile();
      if (p != null) {
        _nameCtrl.text = p.name;
        _taxIdCtrl.text = p.taxId ?? '';
        _streetCtrl.text = p.street ?? '';
        _streetNumberCtrl.text = p.streetNumber ?? '';
        _neighborhoodCtrl.text = p.neighborhood ?? '';
        _cityCtrl.text = p.city ?? '';
        _stateCtrl.text = p.state ?? '';
        _zipCtrl.text = p.zip ?? '';
        _phoneCtrl.text = p.phone ?? '';
        _emailCtrl.text = p.email ?? '';
        _contactCtrl.text = p.contactName ?? '';
        _logoUrl = p.logoUrl;
        _signatureUrl = p.signatureUrl;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final svc = ref.read(companyProfileServiceProvider);
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (res == null || res.files.single.bytes == null) return;
      final bytes = res.files.single.bytes as Uint8List;
      final url = await svc.uploadLogo(bytes);
      setState(() => _logoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo atualizado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao subir logo: $e')));
    }
  }

  Future<void> _pickAndUploadSignature() async {
    try {
      final svc = ref.read(companyProfileServiceProvider);
      final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (res == null || res.files.single.bytes == null) return;
      final bytes = res.files.single.bytes as Uint8List;
      final url = await svc.uploadSignature(bytes);
      setState(() => _signatureUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assinatura atualizada')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao subir assinatura: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final svc = ref.read(companyProfileServiceProvider);
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await svc.upsertProfile(CompanyProfile(
        userId: userId,
        name: _nameCtrl.text.trim(),
        taxId: _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
        street: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
        streetNumber: _streetNumberCtrl.text.trim().isEmpty ? null : _streetNumberCtrl.text.trim(),
        neighborhood: _neighborhoodCtrl.text.trim().isEmpty ? null : _neighborhoodCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        zip: _zipCtrl.text.trim().isEmpty ? null : _zipCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        contactName: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
        logoUrl: _logoUrl,
        signatureUrl: _signatureUrl,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil salvo com sucesso')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taxIdCtrl.dispose();
    _streetCtrl.dispose();
    _streetNumberCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da Empresa')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(labelText: 'Nome da Empresa *'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _taxIdCtrl,
                            decoration: const InputDecoration(labelText: 'CNPJ/CPF'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _streetCtrl,
                            decoration: const InputDecoration(labelText: 'Rua'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _streetNumberCtrl,
                            decoration: const InputDecoration(labelText: 'Número'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _neighborhoodCtrl,
                            decoration: const InputDecoration(labelText: 'Bairro'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration: const InputDecoration(labelText: 'Cidade'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _stateCtrl,
                            decoration: const InputDecoration(labelText: 'UF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: _zipCtrl,
                            decoration: const InputDecoration(labelText: 'CEP'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(labelText: 'Telefone'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactCtrl,
                      decoration: const InputDecoration(labelText: 'Contato (responsável)'),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Logotipo'),
                            subtitle: _logoUrl == null
                                ? const Text('Nenhum logo enviado')
                                : Text(_logoUrl!),
                            trailing: ElevatedButton.icon(
                              onPressed: _pickAndUploadLogo,
                              icon: const Icon(Icons.upload),
                              label: const Text('Enviar'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Assinatura'),
                            subtitle: _signatureUrl == null
                                ? const Text('Nenhuma assinatura enviada')
                                : Text(_signatureUrl!),
                            trailing: ElevatedButton.icon(
                              onPressed: _pickAndUploadSignature,
                              icon: const Icon(Icons.upload),
                              label: const Text('Enviar'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save),
                        label: _saving ? const Text('Salvando...') : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
