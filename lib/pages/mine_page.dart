import 'package:flutter/material.dart';
import 'package:oa_fontend/models/constants/app_colors.dart';
import 'package:oa_fontend/models/constants/text_style.dart';
import 'package:oa_fontend/utils/user_manager.dart';
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
    _loadUserData();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   setState(() {});
    // });
  }

  Future<void> _loadUserData() async {
    await userManager.loadUserInfo();
    if (mounted) {
      setState(() {});
    }
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
        // 保存token信息
        await tokenManager.saveToken(
          accessToken: loginData.accessToken,
          refreshToken: loginData.refreshToken,
          accessTokenExpiry: loginData.accessTokenExpiry,
        );
        // 保存用户基础信息
        await userManager.saveUserInfo(
          username: loginData.username,
          phone: loginData.phone,
          department: loginData.department,
          title: loginData.title,
          role: loginData.role,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('登录成功')));
          setState(() {});
        }
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

  Future<void> _onLogoutPressed() async {
    final logoutSuccess = await apiClient.logout();
    if (!logoutSuccess) return;
    await tokenManager.clearToken();
    await userManager.clearUserInfo();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已退出登录')));
      setState(() {});
    }
  }

  // String _formatUtcToLocal(String utcTimeStr) {
  //   if (utcTimeStr.isEmpty || utcTimeStr == 'null') {
  //     return '未知';
  //   }
  //   try {
  //     DateTime utcDateTime = DateTime.parse(utcTimeStr);
  //     DateTime localDateTime = utcDateTime.toLocal();
  //     return "${localDateTime.year}-${_addZero(localDateTime.month)}-${_addZero(localDateTime.day)} ${_addZero(localDateTime.hour)}:${_addZero(localDateTime.minute)}:${_addZero(localDateTime.second)}";
  //   } catch (e) {
  //     return '格式不对吧';
  //   }
  // }

  // String _addZero(int num) {
  //   return num.toString().padLeft(2, '0');
  // }

  Widget _buildUnloggedInWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            cursorColor: AppColors.primary,
            controller: _accountController,
            decoration: const InputDecoration(
              labelText: '账号',
              hintText: '请输入账号',
              floatingLabelStyle: TextStyle(color: AppColors.primary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.dividerDark, width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            cursorColor: AppColors.primary,
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
              floatingLabelStyle: TextStyle(color: AppColors.primary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.dividerDark, width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 1),
              ),
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
              backgroundColor: AppColors.primary,
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
    final String userName = userManager.username ?? '未知用户';
    final String department = userManager.department ?? '未知部门';
    final String title = userManager.title ?? '未知职位';
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withAlpha(180),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: Center(
                        child: Text(
                          userManager.getLastTwoChars(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              department,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.dividerDark, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: AppTextStyle.middleTips),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dividerDark),
            ),
            child: Column(
              children: [
                _buildFuncItem(
                  icon: Icons.star_border_outlined,
                  title: '收藏',
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('收藏功能开发中')));
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerDark,
                ),
                _buildFuncItem(
                  icon: Icons.settings,
                  title: '设置',
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('设置功能开发中')));
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 56,
                  color: AppColors.dividerDark,
                ),
                _buildFuncItem(
                  icon: Icons.info_outline,
                  title: '关于',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: _onLogoutPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
              child: const Text(
                '退出登录',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('我'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // actions: _isLoggedIn
        //     ? [
        //         Padding(
        //           padding: const EdgeInsets.only(right: 8),
        //           child: IconButton(
        //             onPressed: () => _handleSetting(context),
        //             icon: const Icon(Icons.settings),
        //           ),
        //         ),
        //       ]
        //     : [],
      ),
      body: _isLoggedIn ? _buildLoggedInWidget() : _buildUnloggedInWidget(),
    );
  }

  Widget _buildFuncItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('关于'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                '朝夕-OA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('版本 0.0.1', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text('开发人员：信息开发部', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '确定',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
