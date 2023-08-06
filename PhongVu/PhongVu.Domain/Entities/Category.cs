namespace PhongVu.Domain.Entities
{
	public class Category
	{
		public short CategoryId { get; set; }
		public string CategoryName { get; set; } = null!;
		public string? ImageUrl { get; set; }
		public short? ParentId { get; set; }

		public Category Parent { get; set; }
		public List<Category> Children { get; set; }
	}
}
