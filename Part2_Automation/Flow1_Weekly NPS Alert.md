## Workflow Power Automate: Weekly NPS Alert

### Hình minh họa: Flow1_Weekly NPS Alert.png

### Bước 1: Kích hoạt định kỳ (Recurrence)

- Loại Trigger: Scheduled (Lập lịch).

- Tần suất: 01 lần/tuần vào ngày cố định.

- Mô tả: Khởi động toàn bộ luồng công việc để quét dữ liệu của tuần làm việc vừa qua.

### Bước 2: Truy vấn dữ liệu từ Databricks (Execute a SQL statement)

Hệ thống gửi yêu cầu truy vấn đến Databricks SQL Warehouse để lấy danh sách các bản ghi thỏa mãn điều kiện tiêu cực.

- Nguồn dữ liệu: Bảng bi.nps_survey.

- SQL Query sử dụng:

    ```sql
    SELECT 
        phone_model, 
        nps_comment, 
        nps_score, 
        avg(nps_score) OVER (PARTITION BY phone_model) AS avg_nps_score
    FROM bi.nps_survey
    WHERE 
        -- Filter data lấy tuần trước: từ thứ 2 đến chủ nhật (giả sử bảng này lưu theo ngày bằng cột DATEID)
        DATEID BETWEEN curdate() - INTERVAL 7 DAY AND curdate() - INTERVAL 1 DAY
        AND nps_score IS NOT NULL
    QUALIFY avg_nps_score < 6
    ```
- Trong câu query này giả định bảng `nps_survey` có cột DATEID.

- Logic xử lý dữ liệu:

    Filtering: Chỉ lấy dữ liệu trong khoảng 7 ngày trước đó (sử dụng curdate() - INTERVAL 7 DAY). Loại bỏ các dòng không có điểm số (is not null).

    Aggregation: Sử dụng Window Function avg(nps_score) OVER (PARTITION BY phone_model) để tính điểm trung bình cho từng dòng máy mà vẫn giữ được chi tiết từng comment.

    Qualification: Sử dụng mệnh đề QUALIFY để lọc trực tiếp các dòng máy có điểm trung bình nhỏ hơn 6.

### Bước 3: Chuyển đổi định dạng dữ liệu (Create CSV table)

- Đầu vào: Kết quả JSON từ Bước 2.

- Hành động: Chuyển đổi danh sách các dòng máy và comment sang định dạng bảng CSV.

- Mục đích: Tạo file báo cáo gọn nhẹ để đính kèm vào email.

### Bước 4: Kiểm tra điều kiện (Condition)

Hệ thống kiểm tra xem có bản ghi nào được tìm thấy hay không:

- Trường hợp True (Có dữ liệu): Tồn tại ít nhất một phone_model có điểm NPS trung bình < 6. Tiếp tục sang bước gửi email.

- Trường hợp False (Không có dữ liệu): Tất cả các dòng máy đều đạt chuẩn (> 6).

Hành động: Kết thúc quy trình (Terminate) để tránh gửi thông báo trống gây nhiễu cho người dùng.

### Bước 5: Gửi thông báo và Đính kèm báo cáo (Send an email V2)

- Hành động: Gửi email thông báo tự động.

- Cấu hình Email:

    Người nhận: Team Sales, Product Quality, và Customer Excellence.

    Nội dung: Thông báo danh sách các dòng máy đang gặp vấn đề.

    Đính kèm: File CSV chứa đầy đủ cột phone_model, nps_score, nps_comment và avg_nps_score.