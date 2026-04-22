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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            // 欢迎文字
            const Text(
              '欢迎回来',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.neuTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '登录后即可使用更多功能',
              style: TextStyle(fontSize: 14, color: AppColors.neuTextSecondary),
            ),
            const SizedBox(height: 40),
            // 账号输入框
            _buildInputField(
              controller: _accountController,
              hintText: '请输入账号',
              prefixIcon: Icons.phone_android_outlined,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            // 密码输入框
            _buildInputField(
              controller: _passwordController,
              hintText: '请输入密码',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              enabled: !_isLoading,
            ),
            // 错误提示
            if (_errorMsg.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // 登录按钮
            _buildLoginButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.neuTextSecondary,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 20,
          color: AppColors.neuTextSecondary,
        ),
        filled: true,
        fillColor: AppColors.mainBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    // 这里用GestureDetector(手势检测器)而不是ElevatedButton，是因为这样能很简洁地实现动态的样式
    // 另外，ElevatedButton本质上是套了几层的GestureDetector
    return GestureDetector(
      onTap: _isLoading ? null : _onLoginPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _isLoading
              ? AppColors.primary.withAlpha(153)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(102),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  '登 录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
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
                      color: AppColors.grey,
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
            const Icon(Icons.chevron_right, size: 20, color: AppColors.grey),
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
              Text('版本 0.0.1', style: TextStyle(color: AppColors.grey600)),
              const SizedBox(height: 4),
              Text('开发人员：信息开发部', style: TextStyle(color: AppColors.grey600)),
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
