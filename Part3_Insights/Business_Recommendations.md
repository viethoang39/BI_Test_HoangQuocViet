# 3 Metrics quan trọng cần track
Metric nên được xác định dựa trên mục tiêu muốn thực hiện từ phòng ban kinh doanh. Giả định mục tiêu là duy trì trải nghiệm tốt cho khách hàng và giảm tỉ lệ hủy đơn hàng. 

- NPS Score: Đo lường mức độ hài lòng của khách hàng theo phone model. Chỉ số này giúp nhận diện các nhóm khách hàng có nguy cơ rời bỏ dịch vụ do trải nghiệm không tốt khi dùng dịch vụ và có rủi ro tiềm tàng chia sẻ trải nghiệm qua các kênh MXH hoặc truyền miệng, về dài hạn sẽ ảnh hưởng đến hình ảnh và doanh thu của công ty 
- Order Cancel Rate: Việc theo dõi và tối ưu tỷ lệ này giúp nâng cao hiệu quả trong vận hành, gia tăng doanh thu và thành công trong việc mang lại trải nghiệm tốt cho khách hàng.
- Cancellation Sentiment: Làm rõ việc hủy đơn hàng này đến từ yếu tố khách quan hay chủ quan thông qua các khía cạnh và phần nào lượng hóa được cảm xúc của vấn đề hủy đơn của khách hàng. Từ đó xác định được khía cạnh trọng tâm cần tập trung cải thiện và tối ưu

- Frequency tracking: Daily

- Câu SQL Mẫu:

  ```sql
  -- 1. NPS Score daily tracking by Phone Model
  -- Giả định bảng nps_survey có cột DATEID
  SELECT 
      DATE(DATEID) AS report_date,
      phone_model,
      avg(nps_score) AS nps_score
  FROM bi.nps_survey
  GROUP BY 1, 2
  ORDER BY 1 DESC;

  -- 2. Order Cancel Rate
  -- Giả định bảng orders có trạng thái đơn hàng (status)
  SELECT 
      DATE(DATEID) AS report_date,
      COUNT(CASE WHEN status = 'CANCELLED' THEN 1 END) * 1.0 / COUNT(*) AS cancel_rate
  FROM bi.orders 
  GROUP BY 1;

  -- 3. Cancellation Sentiment Overview
  -- Phân loẹi đơn giản dựa trên từ khóa trong order_cancel_comment
  SELECT 
      DATE(DATEID) AS report_date,
      CASE 
          WHEN LOWER(order_comment) LIKE '%thái độ%' THEN 'Service Attitude'
          WHEN LOWER(order_comment) LIKE '%lâu%' OR LOWER(order_comment) LIKE '%chậm%' THEN 'Delivery Speed'
          ELSE 'Other'
      END AS issue_aspect,
      COUNT(*) AS total_comments
  FROM bi.order_cancel_comment
  GROUP BY 1, 2;
  ```

# 2 Early Warning Signals
- Đối tượng: Sales team

- Dấu hiệu 1: NPS Score giảm đột ngột trong 1 tuần - Khi điểm NPS của một dòng máy (Phone Model) giảm mạnh, điều này báo hiệu một sự cố hệ thống đối với dòng máy đó

    Threshold: Điểm NPS hôm nay thấp hơn phân vị thứ 5 so với điểm NPS score trong vòng 30 ngày theo ngày (ý nghĩa là: Chỉ có 5% số ngày trong lịch sử có điểm thấp hơn mức này vì thế cần lưu ý)
    
- Dấu hiệu 2: Khía cạnh trong cancellation comment tăng đột ngột và mang sắc thái tiêu cực trong 1 tuần - việc cancel đơn hàng tăng là điều đáng lưu tâm trong vận hành và kinh doanh, đặc biệt kèm theo đánh giá từ khách hàng thể hiện trải nghiệm của khách hàng vượt qua ngưỡng chịu đựng nhất định để vào dành thời gian viết đánh giá cụ thể. Việc trích xuất được các khía cạnh từ đánh giá quý giá này giúp công ty nhanh chóng xác định vấn đề và xử lý.

    Threshold: số lượng khía cạnh cụ thể mang sắc thái tiêu cực nhiều hơn hơn phân vị thứ 95 so với trong vòng 30 ngày theo ngày 

- Câu SQL Mẫu:

  ```sql
  -- Dấu hiệu 1: Detect NPS Score Drop (Signal)
  -- Sử dụng window function để tính ngưỡng P5 trong 30 ngày qua
  WITH daily_nps AS (
      SELECT 
          DATE(DATEID) AS report_date,
          phone_model,
          avg(nps_score) AS nps_score
      FROM bi.nps_survey
      GROUP BY 1, 2
  ),
  nps_stats AS (
      SELECT
          report_date,
          phone_model,
          nps_score,
          PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY nps_score) OVER (PARTITION BY phone_model ORDER BY report_date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) as p5_threshold
      FROM daily_nps
  )
  SELECT * 
  FROM nps_stats
  WHERE nps_score < p5_threshold AND report_date = CURRENT_DATE();

  -- Dấu hiệu 2: Negative Aspect Spike Detect
  WITH daily_negative_aspects AS (
      SELECT 
          DATE(DATEID) AS report_date,
          COUNT(*) as negative_aspect_count
      FROM bi.order_cancel_comment
      WHERE LOWER(order_comment) REGEXP 'thái độ|chậm|lâu|hủy|tệ|kém|không' -- Regex match negative keywords
      GROUP BY 1
  ),
  aspect_stats AS (
      SELECT
          report_date,
          negative_aspect_count,
          PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY negative_aspect_count) OVER (ORDER BY report_date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) as p95_threshold
      FROM daily_negative_aspects
  )
  SELECT *
  FROM aspect_stats
  WHERE negative_aspect_count > p95_threshold AND report_date = CURRENT_DATE();
  
# 1 Dashboard Layout
Cấu trúc dashboard (Power BI)

Tham khảo hình ảnh tại file `dashboard_layout.png`

1. Mục tiêu (Objective)
Xây dựng một báo cáo nhằm theo dõi chỉ số NPS (Net Promoter Score) và kiểm soát hiệu quả vận hành qua Tỷ lệ hủy đơn hàng. Dashboard giúp Sales Director, BI manager nhanh chóng nhận diện các điểm nghẽn về dịch vụ và phản hồi của khách hàng theo thời gian.

2. Các chỉ số đo lường chính (Key Metrics)
- NPS Score: Đo lường mức độ hài lòng và sẵn sàng giới thiệu dịch vụ của khách hàng.
- % Order Canceled: Tỷ lệ đơn hàng bị hủy – chỉ số trọng yếu về vận hành.
- Sentiment Analysis: Phân tích sắc thái (Tiêu cực, Trung tính, Tích cực) từ lý do hủy đơn.

- Aspect Analysis: Phân loại các khía cạnh gây ảnh hưởng (Thời gian chờ, Thái độ nhân viên, Tài xế, Lỗi App...).

3. Cấu trúc Dashboard (Layout Breakdown)
Báo cáo được thiết kế theo nguyên tắc từ tổng quan đến chi tiết (High-level to Drilled-down):

- Header & Filters: Cho phép lọc dữ liệu linh hoạt theo Thương hiệu điện thoại (Phone Brand), Model, Khía cạnh (Aspects) và Thời gian (Date Range).
- Top KPI Cards: Hiển thị số liệu mới nhất của ngày hôm qua cùng so sánh tăng/giảm với ngày trước đó để thấy ngay biến động.
- Trend Analysis (Line Charts): * Biểu đồ đường theo dõi biến động NPS theo ngày.
- Biểu đồ đường theo dõi số lượng sắc thái (Sentiment) để phát hiện các "spike" tiêu cực bất thường.
- Performance Heatmap: Ma trận nhiệt hiển thị điểm NPS trung bình theo từng Brand điện thoại qua từng ngày, giúp nhận diện lỗi hệ thống theo thiết bị.
- Contribution & Breakdown (Donut & Bar Charts):
    - Cấu trúc tỷ trọng các loại sắc thái.
    - Phân tích sâu vào các khía cạnh (Aspects) gây ra sự không hài lòng để đưa ra giải pháp xử lý cụ thể.