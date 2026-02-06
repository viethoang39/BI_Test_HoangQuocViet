## Workflow n8n: Tự động gắn Tag CRM bằng AI

### Hình minh họa: Flow2_Auto-tagging CRM.png

### Bước 1: Schedule Trigger (Daily Trigger)

Khởi động workflow theo một khung giờ cố định mỗi ngày.

### Bước 2: HTTP Request - Get data from Databricks

Gửi yêu cầu đến API của Databricks để thực thi câu lệnh SQL lấy dữ liệu thô.

- SQL Query sử dụng:

    ```sql
    SELECT 
        ordernumber, 
        order_comment 
    FROM bi.order_cancel_comment 
    WHERE DATEID = curdate() - 1
    ```

- Trong câu query này giả định rằng bảng `order_cancel_comment` có 2 cột `ordernumber` và `DATEID`, trên thực tế sẽ có 2 trường thông tin này mặc dù file hiện tại không có.

Đầu ra: Danh sách các đối tượng chứa mã đơn hàng và nội dung bình luận hủy đơn.

### Bước 3: Loop Over Items

Vì dữ liệu từ bước 2 trả về là một danh sách (array), node này giúp xử lý từng đơn hàng một (từng dòng một) để đảm bảo AI có thể phân tích chính xác từng nội dung.

Luồng đi: Nhánh loop sẽ đi vào xử lý AI, nhánh done sẽ đi đến bước thông báo cuối cùng.

### Bước 4: Auto-tagging by Gemini (AI Node)

Sử dụng mô hình ngôn ngữ lớn (LLM) để "đọc" và "hiểu" lý do khách hàng hủy đơn.

- Input: Trường order_comment từ bước 2.

- Prompt: "Hãy phân tích bình luận sau và trả về 1 tag duy nhất (ví dụ: Giá cao, Giao lâu, Đổi ý, Lỗi kỹ thuật): {{ $json.order_comment }}"

- Output: Một chuỗi văn bản chứa "Tag" phân loại.

### Bước 5: HTTP Request - Update CRM database

Cập nhật kết quả phân loại từ AI vào database.

Phương thức: POST hoặc PATCH.

Dữ liệu gửi đi: Bao gồm ordernumber để định danh và tag do Gemini vừa tạo ra.

### Bước 6: Notify via Chat when completed

Thông báo cho quản trị viên hoặc team vận hành biết quy trình đã chạy xong.

Ứng dụng: Google Chat.

Nội dung tin nhắn: "Quy trình Auto-tagging CRM đã hoàn tất xử lý cho các đơn hàng ngày hôm qua."