using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Application.Dto.AuthDto;

namespace PhongVu.Application.Features.Auth.Commands
{
    public record RegisterCommandRequest(RegisterDto registerDto) : IRequest<int>;

    public class RegisterCommandHandler : BaseService, IRequestHandler<RegisterCommandRequest, int>
    {
        public RegisterCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(RegisterCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.AuthRepository.Register(request.registerDto));
        }
    }
}
