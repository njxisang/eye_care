/// 时间格式工具函数
/// 统一全应用的时间/minutes 格式化逻辑
class FormatUtils {
  /// 将分钟数格式化为可读字符串
  /// 0~59: "X分钟"
  /// 60+: "Xh" 或 "XhYm"（当 m > 0 时）
  static String formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }

  /// 将秒数格式化为 MM:SS
  static String formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 将 DateTime 格式化为 HH:mm:ss
  static String formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }
}
