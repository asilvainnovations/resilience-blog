import { auth0 } from "@/lib/auth0";
import Link from "next/link";
import Image from "next/image";

export default async function Home() {
  const session = await auth0.getSession();

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900 font-sans antialiased">
      {/* Navigation */}
      <nav className="fixed w-full z-50 bg-white/90 dark:bg-slate-900/90 backdrop-blur-md border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            {/* Logo */}
            <Link href="/" className="flex items-center">
              <div className="h-10 w-10 rounded-lg bg-gradient-to-br from-brand-600 to-brand-accent flex items-center justify-center text-white font-bold text-xl shadow-lg mr-3">
                <Image 
                  src="https://asilvainnovations.com/assets/apps/user_1097/app_13212/draft/icon/app_logo.png?1772636202" 
                  alt="ASilva Innovations" 
                  width={40} 
                  height={40}
                  className="object-contain"
                />
              </div>
              <div className="flex flex-col">
                <span className="font-bold text-lg tracking-tight text-slate-900 dark:text-white">ASilva</span>
                <span className="text-xs text-brand-600 dark:text-brand-400 font-medium uppercase tracking-wider">Innovations</span>
              </div>
            </Link>

            {/* Auth Status */}
            <div className="flex items-center space-x-4">
              {session ? (
                <div className="flex items-center space-x-4">
                  <div className="hidden md:flex items-center space-x-3">
                    <div className="h-8 w-8 rounded-full bg-brand-100 dark:bg-brand-900 flex items-center justify-center">
                      <span className="text-brand-700 dark:text-brand-300 font-semibold text-sm">
                        {session.user.name?.charAt(0) || session.user.email?.charAt(0) || 'U'}
                      </span>
                    </div>
                    <span className="text-sm font-medium text-slate-700 dark:text-slate-300">
                      {session.user.name || session.user.email}
                    </span>
                  </div>
                  <Link 
                    href="/auth/logout"
                    className="px-4 py-2 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 rounded-lg font-medium transition-all text-sm"
                  >
                    Logout
                  </Link>
                </div>
              ) : (
                <div className="flex items-center space-x-3">
                  <Link 
                    href="/auth/login"
                    className="px-4 py-2 text-slate-600 dark:text-slate-300 hover:text-brand-600 dark:hover:text-brand-400 font-medium transition-colors text-sm"
                  >
                    Sign In
                  </Link>
                  <Link 
                    href="/auth/login?screen_hint=signup"
                    className="px-4 py-2 bg-brand-600 hover:bg-brand-700 text-white rounded-lg font-medium transition-all shadow-lg hover:shadow-brand-500/30 text-sm"
                  >
                    Get Started
                  </Link>
                </div>
              )}
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="pt-16">
        {!session ? (
          <UnauthenticatedView />
        ) : (
          <AuthenticatedView session={session} />
        )}
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
}

// Unauthenticated View - Login/Signup Landing
function UnauthenticatedView() {
  return (
    <>
      {/* Hero Section */}
      <section className="relative bg-slate-900 text-white overflow-hidden">
        <div className="absolute inset-0">
          <img 
            src="https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=2000&q=80" 
            className="w-full h-full object-cover opacity-30"
            alt="Resilience"
          />
          <div className="absolute inset-0 bg-gradient-to-r from-slate-900 via-slate-900/90 to-slate-900/70" />
        </div>
        
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24 md:py-32">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div className="animate-fade-in">
              <div className="inline-flex items-center px-3 py-1 rounded-full border border-brand-500/30 bg-brand-500/10 text-brand-300 text-sm font-medium mb-6 backdrop-blur-sm">
                <span className="flex h-2 w-2 rounded-full bg-brand-400 mr-2 animate-pulse" />
                Secure Access Portal
              </div>
              <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight mb-6 leading-tight">
                Access Your <span className="text-gradient">Resilience</span> Dashboard
              </h1>
              <p className="text-xl text-slate-300 mb-8 max-w-lg leading-relaxed">
                Sign in to manage your content, track insights, and collaborate on building resilient communities through technology.
              </p>
              
              {/* Auth Options */}
              <div className="flex flex-col sm:flex-row gap-4">
                <Link 
                  href="/auth/login"
                  className="px-8 py-4 bg-brand-600 hover:bg-brand-700 text-white rounded-lg font-semibold transition-all shadow-lg shadow-brand-600/30 flex items-center justify-center"
                >
                  <i className="fas fa-sign-in-alt mr-2" />
                  Sign In to Account
                </Link>
                <Link 
                  href="/auth/login?screen_hint=signup"
                  className="px-8 py-4 bg-white/10 hover:bg-white/20 backdrop-blur-sm border border-white/20 text-white rounded-lg font-semibold transition-all flex items-center justify-center"
                >
                  <i className="fas fa-user-plus mr-2" />
                  Create Account
                </Link>
              </div>
            </div>

            {/* Signup Iframe Section */}
            <div className="relative">
              <div className="absolute -inset-1 bg-gradient-to-r from-brand-500 to-brand-accent rounded-2xl blur opacity-30" />
              <div className="relative bg-white dark:bg-slate-800 rounded-2xl shadow-2xl overflow-hidden">
                <div className="p-6 border-b border-slate-200 dark:border-slate-700">
                  <h3 className="text-lg font-bold text-slate-900 dark:text-white flex items-center">
                    <i className="fas fa-envelope-open-text text-brand-600 mr-2" />
                    Join Our Newsletter
                  </h3>
                  <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                    Get the latest insights on systems thinking and resilience.
                  </p>
                </div>
                <div className="p-0">
                  <iframe 
                    src="https://cdn.forms-content-1.sg-form.com/04a27688-1855-11f1-8ef1-66216da793cc"
                    className="w-full h-[400px] border-0"
                    title="ASilva Innovations Newsletter Signup"
                    loading="lazy"
                  />
                </div>
                <div className="px-6 py-4 bg-slate-50 dark:bg-slate-900/50 border-t border-slate-200 dark:border-slate-700">
                  <p className="text-xs text-slate-500 dark:text-slate-400 text-center">
                    🔒 Your information is secure. Unsubscribe anytime.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="text-center mb-12">
          <h2 className="text-3xl font-bold text-slate-900 dark:text-white">Platform Access</h2>
          <p className="mt-2 text-slate-600 dark:text-slate-400">Everything you need to build resilient communities.</p>
        </div>
        
        <div className="grid md:grid-cols-3 gap-8">
          <FeatureCard 
            icon="fa-pen-nib"
            color="strategic"
            title="Content Management"
            description="Create and manage insights, articles, and thought leadership pieces."
          />
          <FeatureCard 
            icon="fa-chart-line"
            color="drr"
            title="Analytics Dashboard"
            description="Track engagement, views, and audience growth in real-time."
          />
          <FeatureCard 
            icon="fa-users"
            color="leadership"
            title="Team Collaboration"
            description="Work together with editors, contributors, and stakeholders."
          />
        </div>
      </section>

      {/* Solutions Preview */}
      <section className="bg-slate-100 dark:bg-slate-800/50 py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-slate-900 dark:text-white">Our Solutions</h2>
            <p className="mt-2 text-slate-600 dark:text-slate-400">Enterprise-grade platforms for resilient communities.</p>
          </div>
          
          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            <SolutionCard 
              shortName="StratPlan Pro"
              fullName="Systems & Strategic Thinking"
              color="bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-200"
              icon="fa-chess"
              url="https://asilvainnovations.com/strat-planner-pro"
            />
            <SolutionCard 
              shortName="DDRiVE-M"
              fullName="DRR-CCA Platform"
              color="bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200"
              icon="fa-shield-halved"
              url="https://asilvainnovations.com/ddrive-m"
            />
            <SolutionCard 
              shortName="RTL"
              fullName="Real-Time Leadership"
              color="bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200"
              icon="fa-bolt"
              url="https://asilvainnovations.com/rtl"
            />
          </div>
        </div>
      </section>
    </>
  );
}

// Authenticated View - User Dashboard
function AuthenticatedView({ session }: { session: any }) {
  const user = session.user;

  return (
    <>
      {/* Welcome Banner */}
      <section className="bg-brand-600 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-brand-100 font-medium mb-1">Welcome back,</p>
              <h1 className="text-3xl font-bold">{user.name || user.email}</h1>
              <p className="text-brand-100 mt-2">{user.email}</p>
            </div>
            <div className="mt-6 md:mt-0 flex space-x-3">
              <Link 
                href="/dashboard"
                className="px-6 py-3 bg-white text-brand-700 rounded-lg font-semibold hover:bg-brand-50 transition-colors shadow-lg"
              >
                <i className="fas fa-th-large mr-2" />
                Dashboard
              </Link>
              <Link 
                href="/editor"
                className="px-6 py-3 bg-brand-700 text-white border border-brand-500 rounded-lg font-semibold hover:bg-brand-800 transition-colors"
              >
                <i className="fas fa-plus mr-2" />
                New Article
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Profile & Stats Grid */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid lg:grid-cols-3 gap-8">
          {/* User Profile Card */}
          <div className="lg:col-span-1">
            <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden">
              <div className="h-32 bg-gradient-to-br from-brand-500 to-brand-accent" />
              <div className="px-6 pb-6">
                <div className="relative -mt-12 mb-4">
                  <div className="h-24 w-24 rounded-full bg-white dark:bg-slate-800 p-1 shadow-lg">
                    <div className="h-full w-full rounded-full bg-brand-100 dark:bg-brand-900 flex items-center justify-center">
                      <span className="text-3xl font-bold text-brand-700 dark:text-brand-300">
                        {user.name?.charAt(0) || user.email?.charAt(0) || 'U'}
                      </span>
                    </div>
                  </div>
                </div>
                
                <h2 className="text-xl font-bold text-slate-900 dark:text-white">
                  {user.name || 'User'}
                </h2>
                <p className="text-slate-500 dark:text-slate-400 text-sm">{user.email}</p>
                
                <div className="mt-4 flex flex-wrap gap-2">
                  {user.email_verified && (
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                      <i className="fas fa-check-circle mr-1" /> Verified
                    </span>
                  )}
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-brand-100 text-brand-800 dark:bg-brand-900 dark:text-brand-200">
                    {user.role || 'Editor'}
                  </span>
                </div>

                <div className="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700">
                  <h3 className="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider mb-3">
                    Account Details
                  </h3>
                  <dl className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <dt className="text-slate-500 dark:text-slate-400">Provider</dt>
                      <dd className="text-slate-900 dark:text-slate-200 font-medium">{user.sub?.split('|')[0] || 'Auth0'}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-slate-500 dark:text-slate-400">Last Login</dt>
                      <dd className="text-slate-900 dark:text-slate-200 font-medium">
                        {new Date(user.updated_at).toLocaleDateString()}
                      </dd>
                    </div>
                  </dl>
                </div>

                <div className="mt-6">
                  <Link 
                    href="/auth/logout"
                    className="w-full px-4 py-2 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-900/30 rounded-lg font-medium transition-colors text-center block"
                  >
                    <i className="fas fa-sign-out-alt mr-2" />
                    Sign Out
                  </Link>
                </div>
              </div>
            </div>
          </div>

          {/* Stats & Activity */}
          <div className="lg:col-span-2 space-y-8">
            {/* Quick Stats */}
            <div className="grid sm:grid-cols-3 gap-4">
              <StatCard 
                label="Articles"
                value="12"
                change="+3 this month"
                icon="fa-file-alt"
                color="blue"
              />
              <StatCard 
                label="Total Views"
                value="45.2K"
                change="+12% from last month"
                icon="fa-eye"
                color="cyan"
              />
              <StatCard 
                label="Engagement"
                value="8.4%"
                change="+2.1% from last month"
                icon="fa-heart"
                color="amber"
              />
            </div>

            {/* Recent Activity */}
            <div className="bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700">
              <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex justify-between items-center">
                <h3 className="font-bold text-slate-900 dark:text-white">Recent Activity</h3>
                <Link href="/dashboard" className="text-sm text-brand-600 hover:text-brand-700 font-medium">
                  View all
                </Link>
              </div>
              <div className="divide-y divide-slate-200 dark:divide-slate-700">
                <ActivityItem 
                  action="Published article"
                  target="Architecting Resilience: Systems Thinking in DRR-CCA"
                  time="2 hours ago"
                  icon="fa-check-circle"
                  color="green"
                />
                <ActivityItem 
                  action="Updated draft"
                  target="Strategic Foresight in Uncertain Times"
                  time="Yesterday"
                  icon="fa-edit"
                  color="blue"
                />
                <ActivityItem 
                  action="Received comment"
                  target="From Maria Santos on DRR article"
                  time="3 days ago"
                  icon="fa-comment"
                  color="cyan"
                />
              </div>
            </div>

            {/* Raw User Data (Collapsible for debugging) */}
            <div className="bg-slate-100 dark:bg-slate-900 rounded-2xl p-6">
              <details className="group">
                <summary className="flex justify-between items-center cursor-pointer list-none">
                  <span className="font-semibold text-slate-700 dark:text-slate-300 text-sm">
                    <i className="fas fa-code mr-2" />
                    Session Data (Debug)
                  </span>
                  <span className="transition group-open:rotate-180">
                    <i className="fas fa-chevron-down text-slate-400" />
                  </span>
                </summary>
                <div className="mt-4 overflow-x-auto">
                  <pre className="text-xs text-slate-600 dark:text-slate-400 bg-white dark:bg-slate-800 p-4 rounded-lg border border-slate-200 dark:border-slate-700">
                    {JSON.stringify(user, null, 2)}
                  </pre>
                </div>
              </details>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

// Component Subcomponents

function FeatureCard({ icon, color, title, description }: { icon: string; color: string; title: string; description: string }) {
  const colorClasses = {
    strategic: 'bg-sky-50 text-sky-600 dark:bg-sky-900/30 dark:text-sky-400',
    drr: 'bg-cyan-50 text-cyan-600 dark:bg-cyan-900/30 dark:text-cyan-400',
    leadership: 'bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400',
  };

  return (
    <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 hover:shadow-lg transition-shadow">
      <div className={`w-12 h-12 rounded-xl ${colorClasses[color as keyof typeof colorClasses]} flex items-center justify-center text-xl mb-4`}>
        <i className={`fas ${icon}`} />
      </div>
      <h3 className="font-bold text-slate-900 dark:text-white mb-2">{title}</h3>
      <p className="text-slate-600 dark:text-slate-400 text-sm">{description}</p>
    </div>
  );
}

function SolutionCard({ shortName, fullName, color, icon, url }: { shortName: string; fullName: string; color: string; icon: string; url: string }) {
  return (
    <a 
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className="group block bg-white dark:bg-slate-800 p-8 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700 hover:shadow-2xl hover:border-brand-500 transition-all duration-300 text-center"
    >
      <div className={`w-16 h-16 rounded-2xl ${color} flex items-center justify-center text-3xl mx-auto mb-6 group-hover:scale-110 transition-transform`}>
        <i className={`fas ${icon}`} />
      </div>
      <h3 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">{shortName}</h3>
      <p className="text-slate-500 dark:text-slate-400 mb-4 font-medium">{fullName}</p>
      <span className="inline-flex items-center text-brand-600 font-semibold group-hover:translate-x-1 transition-transform">
        Explore Solution <i className="fas fa-arrow-right ml-2" />
      </span>
    </a>
  );
}

function StatCard({ label, value, change, icon, color }: { label: string; value: string; change: string; icon: string; color: string }) {
  const colorClasses = {
    blue: 'bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400',
    cyan: 'bg-cyan-50 text-cyan-600 dark:bg-cyan-900/30 dark:text-cyan-400',
    amber: 'bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400',
  };

  return (
    <div className="bg-white dark:bg-slate-800 p-6 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-700">
      <div className="flex items-center justify-between mb-4">
        <div className={`w-10 h-10 rounded-lg ${colorClasses[color as keyof typeof colorClasses]} flex items-center justify-center`}>
          <i className={`fas ${icon}`} />
        </div>
        <span className="text-xs font-medium text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/30 px-2 py-1 rounded-full">
          {change}
        </span>
      </div>
      <p className="text-2xl font-bold text-slate-900 dark:text-white">{value}</p>
      <p className="text-sm text-slate-500 dark:text-slate-400">{label}</p>
    </div>
  );
}

function ActivityItem({ action, target, time, icon, color }: { action: string; target: string; time: string; icon: string; color: string }) {
  const colorClasses = {
    green: 'text-green-600 bg-green-50 dark:text-green-400 dark:bg-green-900/30',
    blue: 'text-blue-600 bg-blue-50 dark:text-blue-400 dark:bg-blue-900/30',
    cyan: 'text-cyan-600 bg-cyan-50 dark:text-cyan-400 dark:bg-cyan-900/30',
  };

  return (
    <div className="px-6 py-4 flex items-start space-x-4">
      <div className={`w-8 h-8 rounded-full ${colorClasses[color as keyof typeof colorClasses]} flex items-center justify-center flex-shrink-0 mt-1`}>
        <i className={`fas ${icon} text-xs`} />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-slate-900 dark:text-white">
          {action}
        </p>
        <p className="text-sm text-slate-600 dark:text-slate-300 truncate">
          {target}
        </p>
        <p className="text-xs text-slate-400 mt-1">{time}</p>
      </div>
    </div>
  );
}

function Footer() {
  return (
    <footer className="bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 mt-auto">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          <div className="col-span-1 md:col-span-2">
            <div className="flex items-center mb-4">
              <div className="h-10 w-10 rounded-lg bg-gradient-to-br from-brand-600 to-brand-accent flex items-center justify-center text-white font-bold mr-3">
                <Image 
                  src="https://asilvainnovations.com/assets/apps/user_1097/app_13212/draft/icon/app_logo.png?1772636202" 
                  alt="Logo" 
                  width={40} 
                  height={40}
                  className="object-contain"
                />
              </div>
              <span className="font-bold text-xl text-slate-900 dark:text-white">ASilva Innovations</span>
            </div>
            <p className="text-slate-500 dark:text-slate-400 text-sm leading-relaxed max-w-sm mb-4">
              Building Resilient Communities Through Technology. Enterprise-grade risk intelligence platforms for LGUs, NGOs, and social enterprises across Southeast Asia.
            </p>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">Platform</h3>
            <ul className="space-y-3">
              <li><Link href="/blog" className="text-base hover:text-brand-600 transition-colors">Insights</Link></li>
              <li><Link href="/dashboard" className="text-base hover:text-brand-600 transition-colors">Dashboard</Link></li>
              <li><Link href="/editor" className="text-base hover:text-brand-600 transition-colors">Write</Link></li>
            </ul>
          </div>
          <div>
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">Connect</h3>
            <div className="flex space-x-4">
              <a href="https://facebook.asilvainnovations.com/" className="text-slate-400 hover:text-brand-600 transition-colors"><i className="fab fa-facebook text-xl" /></a>
              <a href="https://linkedin.asilvainnovations.com" className="text-slate-400 hover:text-brand-600 transition-colors"><i className="fab fa-linkedin text-xl" /></a>
              <a href="https://instagram.asilvainnovations.com" className="text-slate-400 hover:text-brand-600 transition-colors"><i className="fab fa-instagram text-xl" /></a>
            </div>
          </div>
        </div>
        <div className="mt-8 border-t border-slate-200 dark:border-slate-800 pt-8 text-center">
          <p className="text-sm text-slate-400">&copy; 2026 ASilva Innovations. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
}
