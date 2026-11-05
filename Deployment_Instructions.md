# Access Cinema deployment

## Run the application locally

The app is an ASP.NET Razor Pages application in `AccessApp/`. It uses SQLite at
`Data Source=/home/app.db` (the App Service persistent home directory), creates
the four tables on startup, and seeds sample films, customers, and showings.

```bash
dotnet run --project AccessApp/AccessApp.csproj
```

## Deploy Azure resources

Install the Azure CLI, run `az login`, and select a subscription. Then deploy:

```bash
bash scripts/deploy.sh --location eastus --subscription "<subscription-id>"
```

The script securely prompts for the SQL administrator password without echoing it.
Use a password of at least 16 characters containing uppercase and lowercase
letters, a number, and a symbol. The password is required and is never stored
in the repository.

The Bicep deployment creates an App Service plan, web app, Azure SQL logical
server, and database. If deploying `infra/main.bicep` directly, read the
password silently and pass it as a deployment parameter:

```bash
read -r -s -p "SQL administrator password: " SQL_ADMIN_PASSWORD
echo
az deployment sub create --location eastus --template-file infra/main.bicep \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD"
unset SQL_ADMIN_PASSWORD
```

Do not put the password in shell history, source files, command transcripts, or
the deployment instructions.

After deployment, execute `AccessApp/Database/schema.sql` against the database
with Azure Data Studio or `sqlcmd`. It creates the tables and the
parameterized stored procedures `FilmsAvailable`, `GetShowingAvailability`, and
`CreateBooking`. Restrict the SQL firewall to the App Service outbound IPs (or
use a private endpoint for production), and store the SQL connection string as
an App Service application setting named `ConnectionStrings__DefaultConnection`.

## Rebuild against Azure SQL

After first testing SQLite, ask the coding agent from this repository:

> Update `AccessApp` to use the deployed Azure SQL database instead of SQLite.
> Read `Deployment_Instructions.md` and `AccessApp/Database/schema.sql`.
> Replace the SQLite repository implementation with `Microsoft.Data.SqlClient`,
> call only the existing parameterized stored procedures (never concatenate SQL),
> preserve the Razor Pages UI and seed behavior, and use the
> `ConnectionStrings__DefaultConnection` App Service setting. Do not remove the
> SQLite fallback unless explicitly requested.
