using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Application.Dto.AuthDto;

namespace PhongVu.Application.Features.Auth.Commands
{
    public record LoginCommandRequest(LoginDto loginDto) : IRequest<PhongVu.Domain.Entities.Member>;

    public class LoginCommandHandler : BaseService, IRequestHandler<LoginCommandRequest, PhongVu.Domain.Entities.Member>
    {
        public LoginCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<PhongVu.Domain.Entities.Member> Handle(LoginCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.AuthRepository.Login(request.loginDto));
        }
    }
}
