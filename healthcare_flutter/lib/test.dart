import 'package:flutter/material.dart';

// ==========================
// 💙 MÀN HÌNH ĐĂNG NHẬP HEALTH LIFE
// ==========================
class LoginScreen extends StatelessWidget {
  final Color primaryColor;
  final Color backgroundColor;
  final AssetImage backgroundImage;

  const LoginScreen({
    super.key,
    this.primaryColor = const Color(0xFF1976D2), // Xanh y tế
    this.backgroundColor = Colors.white,
    this.backgroundImage = const AssetImage("assets/1.png"),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(color: backgroundColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ================= HEADER CLIP =================
              Expanded(
                child: ClipPath(
                  clipper: MyClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: backgroundImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 100.0, bottom: 100.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 80,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "HEALTH LIFE",
                          style: TextStyle(
                            fontSize: 36.0,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Login to your account",
                          style: TextStyle(
                            fontSize: 18.0,
                            // ignore: deprecated_member_use
                            color: primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ================= EMAIL =================
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text(
                  "Email",
                  style: TextStyle(color: Colors.grey, fontSize: 16.0),
                ),
              ),
              _buildInputField(
                icon: Icons.email_outlined,
                hint: "Enter your email",
              ),

              // ================= PASSWORD =================
              const Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10),
                child: Text(
                  "Password",
                  style: TextStyle(color: Colors.grey, fontSize: 16.0),
                ),
              ),
              _buildInputField(
                icon: Icons.lock_outline,
                hint: "Enter your password",
                obscure: true,
              ),

              const SizedBox(height: 20),

              // ================= LOGIN BUTTON =================
              _buildMainButton(
                text: "LOGIN",
                color: primaryColor,
                icon: Icons.arrow_forward,
                onPressed: () {
                  // xử lý đăng nhập
                },
              ),
              // ================= SIGNUP LINK =================
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25.0),
                child: Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "DON'T HAVE AN ACCOUNT?",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _buildInputField({
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      decoration: BoxDecoration(
        border: Border.all(
          // ignore: deprecated_member_use
          color: Colors.grey.withOpacity(0.5),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
            child: Icon(icon, color: Colors.grey),
          ),
          Container(
            height: 30.0,
            width: 1.0,
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.5),
            margin: const EdgeInsets.only(right: 10.0),
          ),
          Expanded(
            child: TextField(
              obscureText: obscure,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MAIN BUTTON =================
  Widget _buildMainButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(icon, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= CLIPPER CHO PHẦN HEADER =================
class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path p = Path();
    p.lineTo(size.width, 0.0);
    p.lineTo(size.width, size.height * 0.85);
    p.arcToPoint(
      Offset(0.0, size.height * 0.85),
      radius: const Radius.elliptical(50.0, 10.0),
    );
    p.lineTo(0.0, 0.0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
