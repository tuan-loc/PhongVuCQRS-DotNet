namespace PhongVu.Application.Dto.AuthDto
{
    public class RegisterDto
    {
        public string MemberId { get; set; }
        public string UserName { get; set; } = null!;
        public string Password { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string FullName { get; set; } = null!;
        public bool Gender { get; set; }
        public int RoleId { get; set; }
    }
}
