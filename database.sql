CREATE DATABASE PhongVuCQRS;
GO;

USE PhongVuCQRS;
GO;

--DROP TABLE Category
CREATE TABLE Category(
	CategoryId SMALLINT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	CategoryName NVARCHAR(64) NOT NULL,
	ImageUrl VARCHAR(32),
	ParentId SMALLINT REFERENCES Category(CategoryId),
);
GO

--DROP TABLE Banner
CREATE TABLE Banner(
	BannerId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
	BannerName NVARCHAR(64) NOT NULL,
	ImageUrl VARCHAR(32),
	BannerTypeId INT NOT NULL REFERENCES BannerType(TypeId),
);
GO
--SELECT * FROM Banner

--DROP TABLE BannerType
CREATE TABLE BannerType(
	TypeId INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	TypeName VARCHAR(64),
)
GO

--SELECT * FROM BannerType


--DROP TABLE Member
CREATE TABLE Member(
	MemberId VARCHAR(32) NOT NULL PRIMARY KEY,
	Username VARCHAR(32) NOT NULL UNIQUE,
	Fullname VARCHAR(64) NOT NULL,
	Email VARCHAR(32) NOT NULL,
	Gender BIT NOT NULL DEFAULT 0
);
GO

--DROP TABLE MemberPassword
CREATE TABLE MemberPassword(
	MemberId VARCHAR(32) NOT NULL,
	Password BINARY(64) NOT NULL,
	CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
	UpdatedDate DATETIME NOT NULL DEFAULT GETDATE(),
	IsDeleted BIT NOT NULL DEFAULT 0,
	PRIMARY KEY(MemberId, Password)
);
GO

--DROP TABLE Role
CREATE TABLE Role(
	RoleId INT NOT NULL PRIMARY KEY,
	RoleName VARCHAR(32) NOT NULL UNIQUE
);
GO
--SELECT * FROM Role

--DROP TABLE MemberInRole
CREATE TABLE MemberInRole(
	MemberId VARCHAR(32) NOT NULL,
	RoleId INT,
	IsDeleted BIT NOT NULL DEFAULT 0
);
GO

CREATE TABLE Product(
	ProductId INT IDENTITY(1,1) NOT NULL,
	ProductName NVARCHAR(64) NOT NULL,
	ImageUrl NVARCHAR(128) NOT NULL,
	Pattern NVARCHAR(16) NULL,
	Description NVARCHAR(max) NOT NULL,
	Quantity SMALLINT NOT NULL,
	QuantitySold INT NOT NULL,
	UnitPrice INT NOT NULL,
	Promotion INT NULL,
	Present nvarchar(128) NULL,
	CategoryId TINYINT NOT NULL,
	UpdatedDate DATETIME NOT NULL DEFAULT GETDATE(),
	Status TINYINT NOT NULL
);
GO

--SELECT * FROM Category

SET IDENTITY_INSERT CATEGORY ON;
INSERT INTO Category(CategoryId, CategoryName, ParentId) VALUES
	(1, N'Laptop', NULL),
	(2, N'Sản phẩm Apple', NULL),
	(3, N'PC - Máy tính bộ', NULL),
	(4, N'PC - Linh kiện máy tính', NULL),
	(5, N'Laptop theo thương hiệu', 1),
	(6, N'Laptop theo cấu hình', 1),
	(7, N'Laptop theo nhu cầu', 1),
	(8, N'Laptop theo giá', 1),
	(9, N'Apple (Macbook)', 5),
	(10, N'Acer', 5),
	(11, N'Asus', 5),
	(12, N'DELL', 5),
	(13, N'HP', 5),
	(14, N'Intel Core i3', 6),
	(15, N'Intel Core i5', 6),
	(16, N'Intel Core i7', 6),
	(17, N'Intel Core i9', 6),
	(18, N'Laptop Gaming', 7),
	(19, N'Laptop văn phòng', 7),
	(20, N'Laptop đồ họa', 7),
	(21, N'Dưới 10 triệu', 8),
	(22, N'10 đến 15 triệu', 8),
	(23, N'15 đến 20 triệu', 8),
	(24, N'Macbook', 2),
	(25, N'IMac', 2),
	(26, N'IPhone IPad', 2),
	(27, N'Macbook Air', 24),
	(28, N'Macbook Pro', 24),
	(29, N'Imac Mini', 25),
	(30, N'IPhone', 26),
	(31, N'IPad', 26);
GO
SET IDENTITY_INSERT CATEGORY OFF;
GO

--SELECT * FROM Category AS Category JOIN Category AS Parent ON Category.CategoryId = Parent.ParentId
--SELECT * FROM Category

DELETE FROM Category WHERE CategoryId = 31;
GO

CREATE PROC LoginMember(
	@Username VARCHAR(16),
	@Password VARBINARY(128)
)AS
	SELECT Member.* FROM Member JOIN MemberPassword ON Member.MemberId = MemberPassword.MemberId AND Username = @Username AND Password = @Password AND IsDeleted = 0;
GO

CREATE PROC ChangePassword(
	@Id CHAR(32),
	@OldPassword VARBINARY(64),
	@NewPassword VARBINARY(64)
)
AS
BEGIN
	IF EXISTS(SELECT * FROM MemberPassword WHERE MemberId = @Id AND Password = @OldPassword)
	BEGIN
		UPDATE MemberPassword SET IsDeleted = 1 WHERE MemberId = @Id AND IsDeleted = 0;
		INSERT INTO MemberPassword(MemberId, Password) VALUES (@Id, @NewPassword);
	END
END
GO

CREATE PROC AddMemberInRole(
	@MemberId CHAR(32),
	@RoleId INT
)
AS
BEGIN
	IF EXISTS(SELECT * FROM MemberInRole WHERE MemberId = @MemberId AND RoleId = @RoleId)
		UPDATE MemberInRole SET IsDeleted = ~IsDeleted WHERE MemberId = @MemberId AND RoleId = @RoleId;
	ELSE
		INSERT INTO MemberInRole(MemberId, RoleId) VALUES (@MemberId, @RoleId);
END
GO

CREATE PROC GetRolesByMember(@Id CHAR(32))
AS
	SELECT Role.*, CAST(IFF(MemberId IS NULL, 0, 1) AS BIT) AS Checked FROM Role LEFT JOIN MemberInRole ON Role.RoleId = MemberInRole.RoleId AND IsDeleted = 0 AND MemberId = @Id;
GO

CREATE PROC EditCategory(
	@CategoryId SMALLINT,
	@CategoryName NVARCHAR(64),
	@ImageUrl VARCHAR(32),
	@ParentId SMALLINT
)
AS
BEGIN
	IF @ImageUrl IS NULL
		UPDATE Category SET CategoryName = @CategoryName, ParentId = @ParentId WHERE CategoryId = @CategoryId;
	ELSE
		UPDATE Category SET CategoryName = @CategoryName, ParentId = @ParentId, ImageUrl = @ImageUrl WHERE CategoryId = @CategoryId;
END
GO

CREATE PROC EditBanner(
	@BannerId INT,
	@BannerName NVARCHAR(64),
	@ImageUrl VARCHAR(32),
	@BannerTypeId INT
)
AS
BEGIN
	IF @ImageUrl IS NULL
		UPDATE Banner SET BannerName = @BannerName, BannerTypeId = @BannerTypeId WHERE BannerId = @BannerId;
	ELSE
		UPDATE Banner SET BannerName = @BannerName, BannerTypeId = @BannerTypeId, ImageUrl = @ImageUrl WHERE BannerId = @BannerId;
END
GO

--DROP PROC RegisterMember
CREATE PROC RegisterMember(
	@MemberId VARCHAR(32),
	@Username VARCHAR(32),
	@Fullname VARCHAR(64),
	@Email VARCHAR(32),
	@RoleId INT,
	@Gender BIT,
	@Password BINARY(64)
)
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM Member WHERE Username = @Username)
		INSERT INTO Member (MemberId, Username, Fullname, Email, Gender) VALUES(@MemberId, @Username, @Fullname, @Email, @Gender);
		INSERT INTO MemberPassword (MemberId, Password) VALUES(@MemberId, @Password);
		INSERT INTO MemberInRole (MemberId, RoleId) VALUES(@MemberId, @RoleId);
END
GO

--SELECT * FROM MemberPassword
-- EXEC LoginMember @Username = tuanloc, @Password = 0x3C9909AFEC25354D551DAE21590BB26E38D53F2173B8D3DC3EEE4C047E7AB1C1EB8B85103E3BE7BA613B31BB5C9C36214DC9F14A42FD7A2FDB84856BCA5C44C2

GO
SET IDENTITY_INSERT [dbo].[Product] ON 
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (4, N'Galaxy Ace Duos S6802', N'20140520011637Samsung Galaxy Ace Duos S6802.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 8, 5000000, 0, N'Tai nghe', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (9, N'Galaxy Core GT-I8262', N'20140520012430Samsung Galaxy Core GT-I8262.jpg', N'', N'<p>&nbsp;</p>

<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 14, 3000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (10, N'Galaxy Grand Duos i9082', N'20140520012537Samsung Galaxy Grand Duos i9082.jpg', N'', N'<p>&nbsp;</p>

<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 2, 6000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (11, N'Galaxy Mega 6.3', N'20140520012657Samsung Galaxy Mega 6.3.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 2, 7000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (12, N'Galaxy Note III SM N9000', N'20140520012733Samsung Galaxy Note III SM N9000.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 1, 10000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (13, N'Galaxy S III I9300', N'20140520012906Samsung Galaxy S III I9300.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 15000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (14, N'Samsung Galaxy S4', N'20140520013000Samsung Galaxy S4 (i9500).jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 13000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (15, N'Samsung Galaxy S5', N'20140520013030Samsung Galaxy S5 (G900H).jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 20000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (16, N'Samsung Galaxy Star GT-S5282', N'20140520013101Samsung Galaxy Star GT-S5282.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 1, 6500000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (17, N'Samsung Galaxy Trend GT-S7560', N'20140520013133Samsung Galaxy Trend GT-S7560.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 8000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (18, N'Samsung Galaxy Trend Lite S7392', N'20140520013228Samsung Galaxy Trend Lite S7392.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 1000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (19, N'Samsung Galaxy Win i8552', N'20140520013252Samsung Galaxy Win i8552.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 800000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (20, N'Samsung Galaxy Y S5360', N'20140520013319Samsung Galaxy Y S5360.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 2000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (21, N'Samsung Rex 60 (C3312R)', N'20140520013346Samsung Rex 60 (C3312R).jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 4500000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (22, N'samsung 5529', N'20140520013422samsung-5529-0032-1-zoom.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 1500000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (23, N'samsung 6657', N'20140520013453samsung-6657-54434-1-zoom.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 5500000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (24, N'Sony Xperia C C2305', N'20140520013542Sony Xperia C C2305.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 10000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (25, N'Sony Xperia M C1905', N'20140520013606Sony Xperia M C1905.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 4000000, 0, N'', 3, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (26, N'HTC 8S', N'201405200138148s.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 8000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (27, N'HTC 8X', N'201405200138368x.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 1, 9000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (28, N'HTC Amaze 4G', N'20140520013910HTC Amaze 4G.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 3000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (29, N'HTC Desire 200', N'20140520013946HTC Desire 200.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 900000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (30, N'HTC desire 300', N'20140520014020htc desire 300.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 6000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (31, N'HTC Desire 302', N'20140520014053HTC Desire 302.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 4000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (32, N'HTC Desire 310', N'20140520014118HTC Desire 310.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 7000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (33, N'HTC Desire 500', N'20140520014158HTC Desire 500.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 1500000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (34, N'HTC desire 501', N'20140520014233htc desire 501.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 5000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (35, N'HTC Desire 600', N'20140520014324HTC Desire 600.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 16000000, 10, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (36, N'HTC Desire C', N'20140520014358HTC Desire C.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 8600000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (37, N'HTC Desire L', N'20140520014444HTC Desire L.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 5000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (38, N'HTC Desire SV', N'20140520014515HTC Desire SV.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 700000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (39, N'HTC Desire U', N'20140520014536HTC Desire U.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 3500000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (40, N'HTC Desire X', N'20140520014606HTC Desire X.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 2000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (41, N'HTC One M8', N'20140520014638HTC One M8.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 9000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (42, N'HTC one', N'20140520014713one.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 20000000, 0, N'', 4, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (43, N'Sony Xperia C C2305', N'20140520014847Sony Xperia C C2305.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 13000000, 0, N'', 5, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (44, N'Sony Xperia P', N'20140520014917Sony Xperia P.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 1, 9000000, 0, N'', 5, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (45, N'Sony Xperia Z', N'20140520015043Sony Xperia Z.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 5000000, 0, N'', 5, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (46, N'Sony Xperia Z2', N'20140520015135Sony Xperia Z2.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 6000000, 0, N'', 5, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (47, N'LG Optimus Z1', N'20140520015320lg1.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 15000000, 0, N'', 6, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (48, N'LG 5080', N'20140520020016lg2.jpg', N'', N'<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 1, 5000000, 0, N'', 6, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (50, N'Connspeed CP3 – Pin sạc dự phòng', N'201405201607091.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 439000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (51, N'Genius ECO-u500 - Pin sạc dự phòng', N'201405201608571 (2).jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 1, 500000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (52, N'Nokia BL-4D – Pin điện thoại', N'201405201611102.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 800000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (53, N'Nokia BL-4J – Pin điện thoại', N'201405201611393.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 400000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (54, N'Reloader 10000 - Pin dự phòng  10000mAh', N'201405201616184.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 600000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (55, N'Samsung EB-L1G6LLUCSTD', N'201405201616445.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 300000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (56, N'Samsung Pouch (EFC-1J9LCEGSTD)', N'20140520161826Samsung Pouch (EFC-1J9LCEGSTD) - Samsung Galaxy Note II.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 636000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (57, N'YSD- PW 037 - Pin sạc dự phòng ', N'201405201622098.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 1000000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (58, N'YSD- PW 006 - Pin sạc dự phòng', N'201405201621247.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>YS455ELACC07VNAMZ-124122</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>439.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">YSD- PW 037</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">10.8x1.5x6.2</td>
		</tr>
		<tr>
			<th>M&agrave;u</th>
			<td style="vertical-align:top">N&acirc;u</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Pin sạc dự ph&ograve;ng</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 300000, 0, N'', 7, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (59, N'iLuv Overlay - iPhone 5', N'20140520162347iLuv Overlay (iCA7H305BLK) - iPhone 5.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 200000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (60, N'Pisen iPhone 4 IP05 – iPhone 44S', N'2014052016280913.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 1, 300000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (61, N'Pisen iPhone 4 IP07 – iPhone 4 4S', N'2014052016275712.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 1, 159000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (62, N'Pisen iPhone 4 IP09 – iPhone 4 / 4S', N'2014052016274111.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 500000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (63, N'Pisen Samsung Galaxy Note I9220', N'20140520162541Pisen Samsung Galaxy Note I9220.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 236000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (64, N'Samsung EF – Galaxy S4 Vàng', N'2014052016261610.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 650000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (65, N'Samsung Pouch - Samsung Galaxy Note II', N'2014052016293614.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 363000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (66, N'Zenus Galaxy Note 3 G-Note Diary', N'2014052016301915.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 160000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (67, N'Zenus Sony Xperia Z1 Minimal Diary', N'2014052016310616.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<td style="vertical-align:top">SKU</td>
			<td style="vertical-align:top">
			<p>PI328ELABC7FANVN-64540</p>
			</td>
		</tr>
		<tr>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Gi&aacute;</td>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">
			<p>159.000 VND</p>
			</td>
		</tr>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">iPhone 4 IP07</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">1 x 11.6 x 6 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Chất liệu</th>
			<td style="vertical-align:top">Nhựa PC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Loại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ốp lưng</td>
		</tr>
		<tr>
			<th>Tương th&iacute;ch</th>
			<td style="vertical-align:top">iPhone 4/4S</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Bảo h&agrave;nh</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">12 th&aacute;ng</td>
		</tr>
		<tr>
			<th>Product warranty in english</th>
			<td style="vertical-align:top">12 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 265000, 0, N'', 8, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (68, N'Bose SIE2i - Tai nghe (Cam)', N'20140520163552tn1.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">S2DUDZ-012</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">13x5x2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">xanh dương</td>
		</tr>
	</tbody>
</table>
', 20, 0, 230000, 0, N'', 9, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (69, N'Jabra Easygo - Tai nghe bluetooth (Trắng)', N'20140520163623tn2.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">S2DUDZ-012</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">13x5x2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">xanh dương</td>
		</tr>
	</tbody>
</table>
', 20, 0, 500000, 0, N'', 9, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (70, N'Skullcandy S2DUDZ-012 - (Xanh dương)', N'20140520163747tn3.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">S2DUDZ-012</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">13x5x2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">xanh dương</td>
		</tr>
	</tbody>
</table>
', 20, 0, 360000, 0, N'', 9, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (71, N'Skullcandy S2IKDZ-003 - Đen', N'20140520163825tn4.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">S2DUDZ-012</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">13x5x2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">xanh dương</td>
		</tr>
	</tbody>
</table>
', 20, 0, 180000, 0, N'', 9, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (72, N'Sony MDR EX450 - Trắng', N'20140520163923tn5.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">S2DUDZ-012</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">13x5x2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">xanh dương</td>
		</tr>
	</tbody>
</table>
', 20, 0, 436000, 0, N'', 9, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (73, N'Sony MH-EX300AP – kèm mic (Đen)', N'20140520164000tn6.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">S2DUDZ-012</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Trung Quốc</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">13x5x2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">xanh dương</td>
		</tr>
	</tbody>
</table>
', 20, 0, 560000, 0, N'', 9, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (74, N'Kingston MicroSDHC Class4', N'20140520164239Kingston MicroSDHC Class4.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">Class 4</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ch&iacute;nh h&atilde;ng</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">0.01 x 0.3 x 0.2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Loại</th>
			<td style="vertical-align:top">MicroSDHC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Dung lượng ổ cứng (GB)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">4</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">24 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">24 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 100000, 0, N'', 10, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (75, N'Sandisk MicroSD Card', N'20140520164311Sandisk MicroSD Card.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">Class 4</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ch&iacute;nh h&atilde;ng</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">0.01 x 0.3 x 0.2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Loại</th>
			<td style="vertical-align:top">MicroSDHC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Dung lượng ổ cứng (GB)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">4</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">24 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">24 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 230000, 0, N'', 10, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (76, N'silicon-power 4G', N'20140520164343silicon-power-1239-150021-1-zoom.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">Class 4</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ch&iacute;nh h&atilde;ng</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">0.01 x 0.3 x 0.2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Loại</th>
			<td style="vertical-align:top">MicroSDHC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Dung lượng ổ cứng (GB)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">4</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">24 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">24 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 620000, 0, N'', 10, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (77, N'Thẻ nhớ Transcend Micro SDHC4 - 4GB', N'20140520164417t1.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">Class 4</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ch&iacute;nh h&atilde;ng</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">0.01 x 0.3 x 0.2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Loại</th>
			<td style="vertical-align:top">MicroSDHC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Dung lượng ổ cứng (GB)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">4</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">24 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">24 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 280000, 30, N'2 Pin chất lượng cao', 10, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (78, N'Toshiba Micro SDHC Class 10', N'20140520164437Toshiba Micro SDHC Class 10.jpg', N'', N'<table style="width:570px">
	<tbody>
		<tr>
			<th>Model</th>
			<td style="vertical-align:top">Class 4</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Sản xuất tại</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Ch&iacute;nh h&atilde;ng</td>
		</tr>
		<tr>
			<th>K&iacute;ch thước sản phẩm (D x R x C cm)</th>
			<td style="vertical-align:top">0.01 x 0.3 x 0.2 cm</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">M&agrave;u</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">Đen</td>
		</tr>
		<tr>
			<th>Loại</th>
			<td style="vertical-align:top">MicroSDHC</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Dung lượng ổ cứng (GB)</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">4</td>
		</tr>
		<tr>
			<th>Bảo h&agrave;nh</th>
			<td style="vertical-align:top">24 th&aacute;ng</td>
		</tr>
		<tr>
			<th style="background-color:rgb(250, 250, 250)">Product warranty in english</th>
			<td style="background-color:rgb(250, 250, 250); vertical-align:top">24 th&aacute;ng</td>
		</tr>
	</tbody>
</table>
', 20, 0, 400000, 0, N'Ốp lưng', 10, CAST(N'2014-05-20T00:00:00.000' AS DateTime), 0)
INSERT [dbo].[Product] ([ProductId], [ProductName], [ImageUrl], [Pattern], [Description], [Quantity], [QuantitySold], [UnitPrice], [Promotion], [Present], [CategoryId], [UpdatedDate], [Status]) VALUES (82, N'Sony Xperia C', N'20140526013154Sony Xperia C C2305.jpg', N'', N'<p>&nbsp;</p>

<table border="0" cellpadding="0" cellspacing="0" style="width:570px">
	<tbody>
		<tr>
			<td rowspan="2" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin chung</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Hệ điều h&agrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Android 4.2.2 (Jelly Bean)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ng&ocirc;n ngữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tiếng Việt, Tiếng Anh</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>M&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại m&agrave;n h&igrave;nh</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">TFT</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;u m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 triệu m&agrave;u</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chuẩn m&agrave;n h&igrave;nh</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Full HD</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Độ ph&acirc;n giải</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1080 x 1920 pixels</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>M&agrave;n h&igrave;nh rộng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">5.0&quot;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>C&ocirc;ng nghệ cảm ứng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Cảm ứng điện dung đa điểm</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Chụp h&igrave;nh &amp; Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Camera sau</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">20.7 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Camera trước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2.0 MP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Đ&egrave;n Flash</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>T&iacute;nh năng camera</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Tự động lấy n&eacute;t, chạm lấy n&eacute;t<br />
			Nhận diện khu&ocirc;n mặt, nụ cười<br />
			Chống rung</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Quay phim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Quay phim FullHD 1080p@30fps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Videocall</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Hỗ trợ VideoCall qua Skype</td>
		</tr>
		<tr>
			<td rowspan="5" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>CPU &amp; RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Tốc độ CPU</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">2.2 GHz</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Số nh&acirc;n</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">4 nh&acirc;n</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chipset</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Qualcomm MSM8974</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>RAM</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">2 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chip đồ họa (GPU)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Adreno 330</td>
		</tr>
		<tr>
			<td rowspan="4" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Bộ nhớ &amp; Lưu trữ</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Danh bạ</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kh&ocirc;ng giới hạn</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bộ nhớ trong (ROM)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">16 GB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Thẻ nhớ ngo&agrave;i</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MicroSD (T-Flash)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Hỗ trợ thẻ tối đa</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">64 GB</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Thiết kế &amp; Trọng lượng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Kiểu d&aacute;ng</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Thanh + Cảm ứng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>K&iacute;ch thước</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">144 x 74 x 8.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Trọng lượng (g)</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">170</td>
		</tr>
		<tr>
			<td rowspan="3" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Th&ocirc;ng tin pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Loại pin</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Pin chuẩn Li-Ion</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Dung lượng pin</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3000 mAh</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Pin c&oacute; thể th&aacute;o rời</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td rowspan="13" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Kết nối &amp; Cổng giao tiếp</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">3G</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">HSDPA, 42 Mbps; HSUPA, 5.76 Mbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>4G</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Loại Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro SIM</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Khe gắn Sim</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">1 Sim</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Wifi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Wi-Fi 802.11 a/b/g/n/ac, dual-band, DLNA, Wi-Fi Direct, Wi-Fi hotspot</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPS</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">A-GPS v&agrave; GLONASS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Bluetooth</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">V4.0 with A2DP</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>GPRS/EDGE</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Up to 107 kbps / Up to 296 kbps</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Jack tai nghe</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">3.5 mm</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>NFC</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối USB</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Kết nối kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Cổng sạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Micro USB</td>
		</tr>
		<tr>
			<td rowspan="6" style="background-color:rgb(246, 246, 246); height:20px; vertical-align:baseline; width:150px !important">
			<p>Giải tr&iacute; &amp; Ứng dụng</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">Xem phim</td>
			<td style="background-color:rgb(252, 252, 252); height:20px; vertical-align:baseline">MP4, WMV, H.263, H.264(MPEG4-AVC)</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Nghe nhạc</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">MP3, WAV, WMA, eAAC+, FLAC</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Ghi &acirc;m</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">C&oacute;</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Giới hạn cuộc gọi</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Kh&ocirc;ng</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>FM radio</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">FM radio với RDS</td>
		</tr>
		<tr>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">
			<p>Chức năng kh&aacute;c</p>
			</td>
			<td style="background-color:rgb(252, 252, 252); border-color:rgb(255, 255, 255); height:20px; vertical-align:baseline">Mạng x&atilde; hội ảo<br />
			Google Search, Maps, Gmail, YouTube, Calendar, Google Talk<br />
			Micro chuy&ecirc;n dụng chống ồn</td>
		</tr>
	</tbody>
</table>
', 20, 0, 6000000, 0, N'Tai nghe chinh hang', 3, CAST(N'2014-05-26T00:00:00.000' AS DateTime), 0)
SET IDENTITY_INSERT [dbo].[Product] OFF
GO