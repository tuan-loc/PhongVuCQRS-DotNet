using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Application.Dto.AuthDto;

namespace PhongVu.Application.Features.Auth.Commands
{
    public record ChangeCommandRequest(ChangeDto changeDto) : IRequest<int>;

    public class ChangeCommandHandler : BaseService, IRequestHandler<ChangeCommandRequest, int>
    {
        public ChangeCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(ChangeCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.AuthRepository.Change(request.changeDto));
        }
    }
}
