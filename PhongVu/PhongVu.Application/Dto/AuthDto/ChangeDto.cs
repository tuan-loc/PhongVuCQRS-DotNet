namespace PhongVu.Application.Dto.AuthDto
{
    public class ChangeDto
    {
        public string Id { get; set; } = null!;
        public string OldPassword { get; set; } = null!;
        public string NewPassword { get; set; } = null!;
    }
}
