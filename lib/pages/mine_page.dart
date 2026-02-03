import 'package:flutter/material.dart';
import '../../utils/api_client.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMsg = '';
  bool get _isLoggedIn =>
      !tokenManager.isAccessTokenExpired() && tokenManager.accessToken != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  Future<void> _onLoginPressed() async {
    final account = _accountController.text.trim(); // 是电话号码
    final password = _passwordController.text.trim();

    if (account.isEmpty || password.isEmpty) {
      setState(() {
        _errorMsg = '用户名和密码不能为空';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    final loginResponse = await apiClient.login(
      account: account,
      password: password,
    );
    setState(() {
      _isLoading = false;
    });

    if (loginResponse.success) {
      final loginData = loginResponse.data!;
      if (loginData.accessToken.isNotEmpty) {
        await tokenManager.saveToken(
          accessToken: loginData.accessToken,
          refreshToken: loginData.refreshToken,
          accessTokenExpiry: loginData.accessTokenExpiry,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('登录成功')));
          setState(() {});
        } else {
          setState(() {
            _errorMsg = loginResponse.message ?? '登录失败，请检查账号密码';
          });
        }
      } else {
        setState(() {
          _errorMsg = loginResponse.message!;
        });
      }
    }
  }

  Future<void> _onLogoutPressed() async {
    final logoutSuccess = await apiClient.logout();
    if (!logoutSuccess) return;
    await tokenManager.clearToken();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已退出登录')));
      setState(() {});
    }
  }

  String _formatUtcToLocal(String utcTimeStr) {
    if (utcTimeStr.isEmpty || utcTimeStr == 'null') {
      return '未知';
    }
    try {
      DateTime utcDateTime = DateTime.parse(utcTimeStr);
      DateTime localDateTime = utcDateTime.toLocal();
      return "${localDateTime.year}-${_addZero(localDateTime.month)}-${_addZero(localDateTime.day)} ${_addZero(localDateTime.hour)}:${_addZero(localDateTime.minute)}:${_addZero(localDateTime.second)}";
    } catch (e) {
      return '格式不对吧';
    }
  }

  String _addZero(int num) {
    return num.toString().padLeft(2, '0');
  }

  Widget _buildUnloggedInWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _accountController,
            decoration: const InputDecoration(
              labelText: '账号',
              hintText: '请输入账号',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 8),
          if (_errorMsg.isNotEmpty)
            Text(
              _errorMsg,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.left,
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _onLoginPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF99DE9F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : const Text('登录', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_pin_circle, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            '当前登录:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Token 有效期至：${_formatUtcToLocal(tokenManager.accessTokenExpiry ?? '')}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _onLogoutPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              '退出登录',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF99DE9F),
        centerTitle: true,
      ),
      body: _isLoggedIn ? _buildLoggedInWidget() : _buildUnloggedInWidget(),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
