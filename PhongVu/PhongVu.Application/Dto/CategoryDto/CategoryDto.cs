namespace PhongVu.Application.Dto.CategoryDto
{
    public class CategoryDto
    {
        public string CategoryName { get; set; } = null!;
        public string? ImageUrl { get; set; }
        public short? ParentId { get; set; }
    }
}
