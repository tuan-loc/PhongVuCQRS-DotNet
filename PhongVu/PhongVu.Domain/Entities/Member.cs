namespace PhongVu.Domain.Entities
{
    public class Member
    {
        public string MemberId { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Fullname { get; set; } = null!;
        public bool Gender { get; set; }

        public List<MemberPassword> MemberPasswords { get; set; }
    }
}
