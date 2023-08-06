namespace PhongVu.Domain.Entities
{
    public class MemberPassword
    {
        public string MemberId { get; set; } = null!;
        public byte[] Password { get; set; } = null!;

        public Member Member { get; set; } = null!;
    }
}
