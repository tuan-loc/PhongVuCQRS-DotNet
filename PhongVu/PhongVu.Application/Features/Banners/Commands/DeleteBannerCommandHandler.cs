using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features.Banners.Commands
{
    public record DeleteBannerCommandRequest(int id) : IRequest<int>;

    public class DeleteBannerCommandHandler : BaseService, IRequestHandler<DeleteBannerCommandRequest, int>
    {
        public DeleteBannerCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(DeleteBannerCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerRepository.Delete(request.id));
        }
    }
}
