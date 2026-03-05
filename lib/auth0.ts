import { Auth0Client } from "@auth0/nextjs-auth0/server";

export const auth0 = new Auth0Client({
  // These come from environment variables
  domain: process.env.AUTH0_DOMAIN!,
  clientId: process.env.AUTH0_CLIENT_ID!,
  clientSecret: process.env.AUTH0_CLIENT_SECRET!,
  secret: process.env.AUTH0_SECRET!,
  
  appBaseUrl: process.env.APP_BASE_URL!,
  
  // Routes
  loginUrl: "/auth/login",
  logoutUrl: "/auth/logout",
  callbackUrl: "/auth/callback",
  
  // Session configuration
  session: {
    rollingDuration: 60 * 60 * 24, // 24 hours
    absoluteDuration: 60 * 60 * 24 * 7, // 7 days
  },
  
  // Authorization parameters
  authorizationParameters: {
    scope: "openid profile email",
  },
});
