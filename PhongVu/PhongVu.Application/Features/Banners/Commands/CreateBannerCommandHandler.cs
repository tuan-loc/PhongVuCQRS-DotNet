using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Banners.Commands
{
    public record CreateBannerCommandRequest(Banner banner) : IRequest<int>;

    public class CreateBannerCommandHandler : BaseService, IRequestHandler<CreateBannerCommandRequest, int>
    {
        public CreateBannerCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(CreateBannerCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerRepository.Add(request.banner));
        }
    }
}
