namespace PhongVu.Application.Dto.AuthDto
{
    public class LoginDto
    {
        public string Username { get; set; } = null!;
        public string Password { get; set; } = null!;
        public bool Remember { get; set; }
    }
}
