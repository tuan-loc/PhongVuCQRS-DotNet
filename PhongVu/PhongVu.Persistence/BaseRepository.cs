using System.Data;

namespace PhongVu.Persistence
{
	public abstract class BaseRepository
	{
		protected IDbConnection connection;
		public BaseRepository(IDbConnection connection) => this.connection = connection;
	}
}
