USE btl2_db;
-- Tìm người mua có điểm thưởng >= 150 VÀ có > 1 địa chỉ.
CALL sp_GetHighValueBuyersWithAddresses(150, 1);

-- Lấy các sản phẩm có ít nhất 1 đơn bị hủy (p_MinCancelledOrders = 1)
-- và có Rating trung bình dưới 4.5 sao (p_MaxAverageRating = 4.5)
-- CALL sp_GetUnderperformingProducts(0, 5);