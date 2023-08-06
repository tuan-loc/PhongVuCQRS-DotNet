using PhongVu.Application.Dto.AuthDto;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Contracts.Persistence
{
    public interface IAuthRepository
    {
        int Register(RegisterDto obj);
        Member Login(LoginDto obj);
        int Change(ChangeDto changeDto);
    }
}
