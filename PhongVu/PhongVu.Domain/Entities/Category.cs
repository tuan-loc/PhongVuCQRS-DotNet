namespace PhongVu.Domain.Entities
{
	public class Category
	{
		public short CategoryId { get; set; }
		public string CategoryName { get; set; } = null!;
		public string? ImageUrl { get; set; }
		public short? ParentId { get; set; }

		public Category Parent { get; set; } = null!;
		public List<Category> Children { get; set; } = null!;
		public List<Product> Products { get; set; } = null!;
	}
}
