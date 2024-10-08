---
title: <p>@EnableBatchProsessing</p>
# date: 2024-09-21 14:00:28
categories: [spring, batch]
tags: [spring,spring_batch,annotation]
author: aram
toc: true
comment: true
---
#spring #spring_batch #annotation


spring batch 기능을 활성화하고 배치 잡을 세팅하기 위한 기본 configuration을 제공한다. 



## 기본적으로 해주는 일들
1. **기본 설정 활성화**
	Spring Batch의 기본 설정이 활성화되며, 이는 배치 작업을 수행하기 위해 필요한 기본적인 인프라 스트럭처(예: JobRepository, JobLauncher 등)를 자동으로 설정한다.
	인프라스트럭처 레이어 : ItemReader, ItemWriter 를 비롯해, 재시작과 관련된 문제를 해결할 수 있는 클래스와 인터페이스를 제공한다.
		
	총 4개의 설정 클래스가 실행된다.
	- 실행되는 순서
		1. **BatchConfigurationSelector**
			`@EnableBatchProcessing` 어노테이션을 처리하는 클래스. 이 클래스는 어떤 Batch 관련 구성 클래스를 사용할 것인지 결정한다.
		2. SimpleBatchConfiguration
			- 기본적인 Spring Batch 구성 요소들을 초기화하는 클래스 - 프록시 객체로 생성됨
			- JobBuilderFactory와 StepBuilderFactory 생성
		3. BatchConfigurerConfiguration  
			`BasicBatchConfigurer` 또는 `DataSourceBatchConfigurer`를 사용하여 추가적으로 구성 요소들을 설정. DataSource가 사용되는 경우에는 `DataSourceBatchConfigurer`가 우선됨.
			- BasicBatchConfigurer  
				- SimpleBatchConfiguration 에서 생성한 프록시 객체의 실제 대상 객체를 생성하는 설정 클래스  
				- 빈으로 의존성 주입 받아서 주요 객체들을 참조해서 사용할 수 있다
		    - JpaBatchConfigurer
				- JPA 관련 객체를 생성하는 설정 클래스  
				- 사용자 정의 BatchConfigurer 인터페이스를 구현하여 사용할 수 있음
		- BatchAutoConfiguration(Spring Boot 환경일 경우)
			- 스프링 배치가 초기화 될 때 자동으로 실행되는 설정 클래스.DataSource 설정, 인프라 구성 등을 포함
			- Job을 수행하는 JobLauncherApplicationRunner 빈을 생성  
			    - JobLauncherApplicationRunner 는 ApplicationRunner 구현체
		
2. **간편한 Job 설정**:
	`JobBuilderFactory` 및 `StepBuilderFactory` 빈이 생성되어 배치 작업(Job)과 단계를 쉽게 설정할 수 있게 해준다.
3. **트랜잭션 관리**:
	배치 작업의 트랜잭션 관리가 자동으로 설정.
	**@EnableBatchProcessing은 JDBC기반으로 빈을 설정하기 때문에 DataSource와 PlatformTransactionManager를 빈으로 제공해야 한다.** 
4. . **기본 리스너 설정**
	배치 작업의 상태를 모니터링하고, 필요에 따라 후처리를 수행할 수 있는 기본 리스너들이 설정.



> - JobRepository : 실행중인 잡의 상태를 기록하는데 사용  
> - JobLauncher : 잡을 구동하는데 사용  
> - JobExplorer : JobRepository를 사용해 읽기 전용 작업을 수행하는데 사용  
> - JobRegistry : 특정한 런처 구현체를 사용할때 잡을 찾는 용도로 사용  
> - PlaformTransactionManager : 잡 진행 과정에서 트랜잭션을 다루는데 사용  
> - JobBuilderFactory : 잡을 생성하는 빌더  
> - StepBuilderFactory : 스텝을 생성하는 빌더


configuration이 `modular=true` 로 설정되어있으면 context는 AutomaticJobRegistrar를 포함하고 있다.  job registrar는 job이 여러개인 경우 configuration을 모듈화 할 때 유용하다.  job registrar는 job configuration을 포함시키기 위해 여러개의 자식 application context를 만들고 job들을 등록한다. job들은 빈 정의나 이름 중복과 같은 충돌 걱정 없이 각각 독립적인 환경을 구성할 수 있다. 

## 코드 따라가기

``` java
@Target({ElementType.TYPE})  
@Retention(RetentionPolicy.RUNTIME)  
@Documented  
@Import({BatchConfigurationSelector.class})  
public @interface EnableBatchProcessing {  
    boolean modular() default false;  
}
```
기본적으로 `BatchConfigurationSelector`를 통해 배치 설정 클래스를 선택하고 등록하는 것을 알 수 있다


```java
public class BatchConfigurationSelector implements ImportSelector {  
    public BatchConfigurationSelector() {  
    }  
  
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {  
        Class<?> annotationType = EnableBatchProcessing.class;  
        AnnotationAttributes attributes = AnnotationAttributes.fromMap(importingClassMetadata.getAnnotationAttributes(annotationType.getName(), false));  
        Assert.notNull(attributes, String.format("@%s is not present on importing class '%s' as expected", annotationType.getSimpleName(), importingClassMetadata.getClassName()));  
        String[] imports;  
        if (attributes.containsKey("modular") && attributes.getBoolean("modular")) {  
            imports = new String[]{ModularBatchConfiguration.class.getName()};  
        } else {  
            imports = new String[]{SimpleBatchConfiguration.class.getName()};  
        }  
  
        return imports;  
    }  
}
```
위 코드를 보면 `SimpleBatchConfiguration` 클래스가 구성 클래스 중 하나로 선택되는 것을 알 수 있습니다

```java
  
@Configuration(  
    proxyBeanMethods = false  
)  
public class SimpleBatchConfiguration extends AbstractBatchConfiguration {  
    @Autowired  
    private ApplicationContext context;  
    private boolean initialized = false;  
    private AtomicReference<JobRepository> jobRepository = new AtomicReference();  
    private AtomicReference<JobLauncher> jobLauncher = new AtomicReference();  
    private AtomicReference<JobRegistry> jobRegistry = new AtomicReference();  
    private AtomicReference<PlatformTransactionManager> transactionManager = new AtomicReference();  
    private AtomicReference<JobExplorer> jobExplorer = new AtomicReference();  
  
    public SimpleBatchConfiguration() {  
    }  
  
    @Bean  
    public JobRepository jobRepository() throws Exception {  
        return (JobRepository)this.createLazyProxy(this.jobRepository, JobRepository.class);  
    }  
  
    @Bean  
    public JobLauncher jobLauncher() throws Exception {  
        return (JobLauncher)this.createLazyProxy(this.jobLauncher, JobLauncher.class);  
    }  
  
    @Bean  
    public JobRegistry jobRegistry() throws Exception {  
        return (JobRegistry)this.createLazyProxy(this.jobRegistry, JobRegistry.class);  
    }  
  
    @Bean  
    public JobExplorer jobExplorer() {  
        return (JobExplorer)this.createLazyProxy(this.jobExplorer, JobExplorer.class);  
    }  
  
    @Bean  
    public PlatformTransactionManager transactionManager() throws Exception {  
        return (PlatformTransactionManager)this.createLazyProxy(this.transactionManager, PlatformTransactionManager.class);  
    }
    
private <T> T createLazyProxy(AtomicReference<T> reference, Class<T> type) {  
    ProxyFactory factory = new ProxyFactory();  
    factory.setTargetSource(new ReferenceTargetSource(reference));  
    factory.addAdvice(new PassthruAdvice());  
    factory.setInterfaces(new Class[]{type});  
    T proxy = factory.getProxy();  
    return proxy;  
}
...
}
```
`SimpleBatchConfiguration` 클래스는 실제로 여러 @Bean 정의를 포함하고 있어, 배치 애플리케이션에 필요한 여러 기본 빈들을 자동으로 설정합니다.
