namespace PhongVu.Domain.Entities
{
    public class Banner
    {
        public int BannerId { get; set; }
        public string BannerName { get; set; } = null!;
        public string ImageUrl { get; set; } = null!;
        public int BannerTypeId { get; set; }
        public string BannerTypeName { get; set; } = null!;
    }
}
