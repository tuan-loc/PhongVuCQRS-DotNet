using Dapper;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Application.Dto.AuthDto;
using PhongVu.Domain.Entities;
using PhongVu.Infrastructure;
using System.Data;

namespace PhongVu.Persistence
{
    public class AuthRepository : BaseRepository, IAuthRepository
    {
        public AuthRepository(IDbConnection connection) : base(connection)
        {
        }

        public int Register(RegisterDto entity)
        {
            return connection.Execute("RegisterMember", new
            {
                MemberId = entity.MemberId,
                Username = entity.UserName,
                Fullname = entity.FullName,
                Email = entity.Email,
                RoleId = entity.RoleId,
                Gender = entity.Gender,
                Password = Helper.Hash(entity.Password)
            }, commandType: CommandType.StoredProcedure);
        }

        public PhongVu.Domain.Entities.Member Login(LoginDto obj)
        {
            return connection.QueryFirstOrDefault<PhongVu.Domain.Entities.Member>("LoginMember", new {
                Username = obj.Username,
                Password = Helper.Hash(obj.Password),
            }, commandType: CommandType.StoredProcedure);
        }

        public int Change(ChangeDto changeDto)
        {
            return connection.Execute("ChangePassword", new
            {
                Id = changeDto.Id,
                OldPassword = Helper.Hash(changeDto.OldPassword),
                NewPassword = Helper.Hash(changeDto.NewPassword),
            }, commandType: CommandType.StoredProcedure);
        }
    }
}
